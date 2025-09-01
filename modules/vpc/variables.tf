variable "vpc_cidr" { type = string }
variable "public_subnet_cidr" { type = string }
variable "private_subnet_cidrs" { type = list(string) }
variable "azs" { type = list(string) }
variable "tags" { type = map(string) }