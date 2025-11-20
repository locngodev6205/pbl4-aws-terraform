data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = "locngodev"

    workspaces = {
      name = "pbl4-network"
    }
  }
}

locals {
  current_workspace = terraform.workspace
  
  vpc_id                       = data.terraform_remote_state.network.outputs.vpc_id
  aws_region                   = data.terraform_remote_state.network.outputs.aws_region
  key_pair_name                = data.terraform_remote_state.network.outputs.key_pair_name
  public_subnet_ids            = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_app_subnet_ids       = data.terraform_remote_state.network.outputs.private_app_subnet_ids

  external_app_alb_sg_id       = data.terraform_remote_state.network.outputs.external_app_alb_sg_id
  app_sg_id                    = data.terraform_remote_state.network.outputs.app_sg_id
  external_app_arn             = data.terraform_remote_state.network.outputs.alb_app_arn
  alb_app_dns_name             = data.terraform_remote_state.network.outputs.alb_app_dns_name

  ec2_ecr_instance_profile_name = data.terraform_remote_state.network.outputs.ec2_ecr_instance_profile_name
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default = "v1.0.10"
}

variable "port" {
  description = "Port for the ALB listener"
  type        = number
  default     = 80
}