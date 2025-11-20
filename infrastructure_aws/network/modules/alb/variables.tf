variable "project_name" {
  description = "Name of the project"
  type        = string
  default = "pbl4"
}
variable "external_web_alb_sg_id" {
  description = "Security group ID for external ALB"
  type        = string
}
variable "external_app_alb_sg_id" {
  description = "Security group ID for external ALB"
  type        = string
}
variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}