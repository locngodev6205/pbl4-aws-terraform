variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "key_name" { type = string }
variable "allocate_eip" { type = bool }
variable "user_data_path" { type = string }
variable "tags" { type = map(string) }