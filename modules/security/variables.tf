variable "vpc_id"            { type = string }
variable "allow_http_cidr"   { type = string }
variable "allow_https_cidr"  { type = string }
variable "allowed_ssh_cidrs" { type = list(string) }
variable "tags"              { type = map(string) }