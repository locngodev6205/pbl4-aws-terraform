variable "region" { type = string }
variable "project" { type = string }
variable "env" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidr" { type = string }
variable "private_subnet_cidrs" { type = list(string) }
variable "azs" { type = list(string) }
variable "instance_type" { type = string }
variable "allowed_ssh_cidrs" { type = list(string) }
variable "key_name" { type = string }
variable "public_key_path" { type = string }

variable "db_username" {
  type        = string
  description = "Username for the RDS database."
}
variable "db_password" {
  type        = string
  description = "Password for the RDS database."
  sensitive   = true # 'sensitive = true' sẽ giấu giá trị này trong log.
}

variable "alert_email" {
  type        = string
  description = "Email nhận cảnh báo CloudWatch."
}