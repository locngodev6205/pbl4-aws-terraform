variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "pbl4-three-tier"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "db_username" {
  description = "DB master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "DB master password"
  type        = string
  sensitive   = true
  default     = "pbl4_123456"
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "pbl4-keypair"
}
