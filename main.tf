#############################################################
# EC2 Launch Template
##############################################################
resource "aws_launch_template" "nginx" {
  name_prefix   = "nginx-launch-template"
  image_id       = "ami-0d91395028b3ba026"
  instance_type  = "t2.micro"
  key_name       = var.key_name

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install -y nginx1
                systemctl start nginx
                systemctl enable nginx
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "ngnixbucket" {
  bucket_prefix = "ngnix-bucket-"
  
  tags = {
    Name        = "ngnix-bucket"
    Environment = "production"
  }
}
####################################################################
# Security Groups
###############################################################
resource "aws_security_group" "allow_alb" {
  vpc_id = "vpc-07877dd24982e2ec0"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.20.246.0/25"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.20.246.0/25"]
  }

  tags = {
    Name = "allow-alb"
  }
}

resource "aws_security_group" "allow_ec2" {
  vpc_id = "vpc-07877dd24982e2ec0"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = "sg-00e53be32fbe029ca"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-ec2"
  }
}
#####################################################################
#subnets 
############################################################
resource "aws_subnet" "sub" {
  for_each = var.subnetlist

  vpc_id                  = "vpc-07877dd24982e2ec0"
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = each.value.tags
}
#######################################################################
# Auto Scaling Group
######################################################################
resource "aws_autoscaling_group" "nginx" {
  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  min_size          = var.min_size
  max_size          = var.max_size
  desired_capacity  = var.desired_capacity
  vpc_zone_identifier = aws_subnet.public[*].id
  health_check_type = "EC2"
  health_check_grace_period = 300
  tag {
    key                 = "Name"
    value               = "nginx-instance"
    propagate_at_launch = true
  }
}

################################################
#Internet gateway 
###################################################
resource "aws_internet_gateway" "PCP_PROD_USW2_IGW" {
  vpc_id = "vpc-07877dd24982e2ec0"

  tags = {
    Name = "PCP_PROD_USW2_IGW"
  }
}
####################################################################
#route tables
###################################################################
resource "aws_route_table" "public" {
  vpc_id = "vpc-07877dd24982e2ec0"

  route {
    cidr_block = "172.20.246.0/25"
    gateway_id = "igw-01bc5a792c26d7816"
  }

  tags = {
    Name = "PCP_PROD_USW2_IGW"
  }
}

resource "aws_route_table_association" "public" {
  #count          = var.az_count * var.public_subnet_per_az
  subnet_id      = ["subnet-08732c757ccec7395" , "subnet-011e91982e8f57307"]
  route_table_id = "rtb-02aa9b66857faeff6"
}

resource "aws_route_table" "private" {
  vpc_id = "vpc-07877dd24982e2ec0"

  tags = {
    Name = "PCP_PROD_USW2_RT"
  }
}

resource "aws_route_table_association" "private" {
  #count          = var.az_count * var.private_subnet_per_az
  subnet_id      = ["subnet-09088c806b31f6f30" , "subnet-082cd060fc160410e"]
  route_table_id = aws_route_table.private.id
}
#######################################################
# Application Load Balancer (ALB)
#######################################################
resource "aws_lb" "app" {
  name               = "my-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = "sg-00e53be32fbe029ca"
  subnets            = "PUBLIC_SUBNET_AZ_2A"

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "MyAppALB"
  }
}
###########################################################
#Target Group
###################################################

resource "aws_lb_target_group" "web" {
  name     = "web-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }

  tags = {
    Name = "web-targets"
  }
}
###########################################################
#lb listener
#################################################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
######################################################
#autoscaling attachment 
########################################################
resource "aws_autoscaling_attachment" "alb" {
  autoscaling_group_name = aws_autoscaling_group.nginx.name
  lb_target_group_arn    = aws_lb_target_group.web.arn
}
