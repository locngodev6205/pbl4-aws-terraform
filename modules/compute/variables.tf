variable "ami_id" {
  description = "AMI ID for the instance."
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start."
  type        = string
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in."
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate."
  type        = list(string)
}

variable "key_name" {
  description = "The key name of the Key Pair to use for the instance."
  type        = string
}

variable "allocate_eip" {
  description = "Whether to allocate an Elastic IP to the instance."
  type        = bool
  default     = true
}

# Các biến mới để hỗ trợ user_data linh hoạt
variable "user_data" {
  description = "User data to provide when launching the instance, as a string."
  type        = string
  default     = null
}

variable "user_data_path" {
  description = "Path to a file containing user data, for backward compatibility."
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Whether to trigger a replacement of the instance when user data changes."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}