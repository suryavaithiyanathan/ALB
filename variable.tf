#variable "vpc_cidr_block" {
 # description = "The CIDR block for the VPC"
 # type        = string
 # default     = "10.0.0.0/16"
#}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the key pair to use for the EC2 instances"
  type        = string
  default     = "test"
}

variable "min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2
}

data "aws_availability_zones" "available" {}

variable "subnetlist" {
  type = map(object({
    cidr_block               = string
    availability_zone        = string
    map_public_ip_on_launch  = bool
    tags                     = map(string)
  }))
  default = {
    "PUBLIC_SUBNET_AZ_2A" = {
      cidr_block               = "172.20.246.0/28"
      availability_zone        = "us-west-2a"
      map_public_ip_on_launch  = true
      tags                     = {
        Name = "PUBLIC_SUBNET_AZ_2A"
      }
    },
    "PUBLIC_SUBNET_AZ_2B" = {
      cidr_block               = "172.20.246.16/28"
      availability_zone        = "us-west-2b"
      map_public_ip_on_launch  = true
      tags                     = {
        Name = "PUBLIC_SUBNET_AZ_2B"
      }
    },
    "PRIVATE_SUBNET_AZ_2A" = {
      cidr_block               = "172.20.246.32/27"
      availability_zone        = "us-west-2a"
      map_public_ip_on_launch  = false
      tags                     = {
        Name = "PRIVATE_SUBNET_AZ_2A"
      }
    },
    "PRIVATE_SUBNET_AZ_2B" = {
      cidr_block               = "172.20.246.64/27"
      availability_zone        = "us-west-2b"
      map_public_ip_on_launch  = false
      tags                     = {
        Name = "PRIVATE_SUBNET_AZ_2B"
      }
    }
  }
}

variable "region" {
  default = "us-west-2"
}

#variable "vpc_id" {
 # description = "The ID of the VPC"
 # type        = string
#}

variable "subnet_ids" {
  description = "The IDs of the subnets to launch the instances"
  type        = list(string)
}

variable "security_group_ids" {
  description = "The IDs of the security groups to assign to the instances"
  type        = list(string)
}