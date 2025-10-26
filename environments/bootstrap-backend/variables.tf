variable "region" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = { project = "pbl4-aws-terraform", env = "dev" }
}
