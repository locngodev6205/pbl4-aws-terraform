locals {
  current_workspace = terraform.workspace
}

# variable "project_name" {
#   description = "Name of the project"
#   type        = string
#   default     = "pbl4"
# }

variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "ap-southeast-1"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  # default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.21.0/24", "10.0.22.0/24", "10.0.31.0/24", "10.0.32.0/24"]
  default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

# variable "db_username" {
#   description = "DB master username"
#   type        = string
#   default     = "admin"
# }

# variable "db_password" {
#   description = "DB master password"
#   type        = string
#   # default     = "pbl4-123456" # Đã đưa lên terraform cloud (Hashicorp)
# }

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "pbl4-keypair"
}

variable "bastion_ami_id" {
  description = "AMI ID for the bastion host"
  type        = string
  default     = "ami-00d8fc944fb171e29" # Amazon Linux 2 in ap-southeast-1
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

# terraform plan --var-file "terraform.tfvars"