variable "project_name" {
  description = "Name of the project"
  type        = string
  default = "pbl4"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "external_app_arn" {
  description = "ARN of the external app ALB"
  type        = string
}

variable "port" {
  description = "Port for the ALB listener"
  type        = number
}