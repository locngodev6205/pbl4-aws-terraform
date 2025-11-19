data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = "locngodev"

    workspaces = {
      name = "pbl4-network"
    }
  }
}

data "terraform_remote_state" "server" {
  backend = "remote"

  config = {
    organization = "locngodev"

    workspaces = {
      name = replace(terraform.workspace, "-client-", "-server-")
    }
  }
}


locals {
  current_workspace = terraform.workspace
  
  vpc_id                       = data.terraform_remote_state.network.outputs.vpc_id
  aws_region                   = data.terraform_remote_state.network.outputs.aws_region
  key_pair_name                = data.terraform_remote_state.network.outputs.key_pair_name
  public_subnet_ids            = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_web_subnet_ids       = data.terraform_remote_state.network.outputs.private_web_subnet_ids

  external_web_alb_sg_id       = data.terraform_remote_state.network.outputs.external_web_alb_sg_id
  web_sg_id                    = data.terraform_remote_state.network.outputs.web_sg_id

  ec2_ecr_instance_profile_name = data.terraform_remote_state.network.outputs.ec2_ecr_instance_profile_name

  alb_app_dns_name = try (
    data.terraform_remote_state.server.outputs.alb_app_dns_name, "http://localhost:3000"
  )

}

# variable "project_name" {
#   description = "Name of the project"
#   type        = string
#   default     = "pbl4"
# }

variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "ap-southeast-1"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default = "v1.0.10"
}

# terraform plan --var-file "terraform.tfvars"