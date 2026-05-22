variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy resources"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Base CIDR block for the VPC"
}


variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "CIDR blocks for public subnets (Requires at least 2)"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
  description = "CIDR blocks for private subnets (Requires at least 2)"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for the web servers"
}

variable "asg_min_size" {
  type        = number
  default     = 2
  description = "Minimum number of instances in the ASG"
}

variable "asg_max_size" {
  type        = number
  default     = 4
  description = "Maximum number of instances in the ASG"
}

variable "asg_desired_capacity" {
  type        = number
  default     = 2
  description = "Desired number of instances in the ASG"
}