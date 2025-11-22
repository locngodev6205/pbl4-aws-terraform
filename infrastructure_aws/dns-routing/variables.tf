data "terraform_remote_state" "blue" {
  backend = "remote"
  config = {
    organization = "locngodev"
    workspaces = {
      name = "pbl4-client-blue"
    }
  }
}

data "terraform_remote_state" "green" {
  backend = "remote"
  config = {
    organization = "locngodev"
    workspaces = {
      name = "pbl4-client-green"
    }
  }
}

variable "active_color" {
  type    = string
  default = "blue"  # hoặc "green"
}

variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "ap-southeast-1"
}

locals {
  active_alb_dns_name = var.active_color == "blue" ? try(data.terraform_remote_state.blue.outputs.alb_web_dns_name, "") : try(data.terraform_remote_state.green.outputs.alb_web_dns_name, "")

  active_alb_zone_id = var.active_color == "blue" ? try(data.terraform_remote_state.blue.outputs.alb_zone_web_id, "") : try(data.terraform_remote_state.green.outputs.alb_zone_web_id, "")
}


