variable "project_name" {
  description = "Name of the project"
  type        = string
}

# variable "web_ami_id" {
#   description = "AMI ID for web"
#   type        = string
#   default     = "ami-00d8fc944fb171e29"
# }

variable "app_ami_id" {
  description = "AMI ID for app"
  type        = string
  default     = "ami-00d8fc944fb171e29"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# variable "web_ecr_image" {
#   description = "Full ECR image URI for web tier"
#   type        = string
#   default = "120915930136.dkr.ecr.ap-southeast-1.amazonaws.com/pbl4-quickshow-frontend"
# }

variable "app_ecr_image" {
  description = "Full ECR image URI for app tier"
  type        = string
  default = "120915930136.dkr.ecr.ap-southeast-1.amazonaws.com/pbl4-quickshow-backend"
}

variable "image_tag" {
  description = "Tag for the Docker images"
  type        = string
  default     = "latest"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

# variable "web_sg_id" {
#   description = "Security group ID for Web"
#   type        = string
# }

variable "app_sg_id" {
  description = "Security group ID for App"
  type        = string
}

variable "min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 1
}

# variable "private_web_subnet_ids" {
#   description = "List of private web subnet IDs"
#   type        = list(string)
# }

variable "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  type        = list(string)
}

# variable "web_target_group_arn" {
#   description = "ARN of the web target group"
#   type        = string
# }

variable "app_target_group_arn" {
  description = "ARN of the app target group"
  type        = string
}

variable "alb_app_dns_name" {
  description = "DNS name of the internal ALB"
  type        = string
}

# variable "db_host" {
#   description = "Database host"
#   type        = string
# }

# variable "db_username" {
#   description = "Database username"
#   type        = string
# }

# variable "db_password" {
#   description = "Database password"
#   type        = string
# }

variable "ec2_instance_profile_name" {
  description = "The name of the IAM instance profile for EC2"
  type        = string
  default     = ""
}
