variable "subnet_group_name" {
  description = "The name of the DB Subnet Group to associate."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "A list of VPC security groups to associate."
  type        = list(string)
}

variable "engine" {
  description = "The database engine to use."
  type        = string
  default     = "mysql"
}

# Bỏ engine_version để AWS tự động chọn phiên bản ổn định mới nhất.
# Điều này giúp tránh lỗi nếu phiên bản "8.0" không còn được hỗ trợ.

variable "instance_class" {
  description = "The instance type of the RDS instance."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created."
  type        = string
  default     = "pbl4db"
}

variable "username" {
  description = "The master username for the database."
  type        = string
}

variable "password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for."
  type        = number
  default     = 0 # Tắt backup cho môi trường dev
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}