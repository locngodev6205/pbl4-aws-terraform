data "terraform_remote_state" "web_blue" {
  backend = "remote"
  config = {
    organization = "locngodev"
    workspaces = {
      name = "pbl4-client-blue"
    }
  }
}

data "terraform_remote_state" "web_green" {
  backend = "remote"
  config = {
    organization = "locngodev"
    workspaces = {
      name = "pbl4-client-green"
    }
  }
}

data "terraform_remote_state" "app_blue" {
  backend = "remote"
  config = {
    organization = "locngodev"
    workspaces = {
      name = "pbl4-server-blue"
    }
  }
}
data "terraform_remote_state" "app_green" {
  backend = "remote"
  config = {
    organization = "locngodev"
    workspaces = {
      name = "pbl4-server-green"
    }
  }
}


variable "active_color_web" {
  type    = string
  default = "blue"  # hoặc "green"
}
variable "active_color_app" {
  type    = string
  default = "blue"  # hoặc "green"
}
variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "ap-southeast-1"
}

locals {
  active_alb_web_dns_name = var.active_color_web == "blue" ? try(data.terraform_remote_state.web_blue.outputs.alb_web_dns_name, "") : try(data.terraform_remote_state.web_green.outputs.alb_web_dns_name, "")
  active_alb_web_zone_id = var.active_color_web == "blue" ? try(data.terraform_remote_state.web_blue.outputs.alb_zone_web_id, "") : try(data.terraform_remote_state.web_green.outputs.alb_zone_web_id, "")

  active_alb_app_dns_name = var.active_color_app == "blue" ? try(data.terraform_remote_state.app_blue.outputs.alb_app_dns_name, "") : try(data.terraform_remote_state.app_green.outputs.alb_app_dns_name, "")
  active_alb_app_zone_id = var.active_color_app == "blue" ? try(data.terraform_remote_state.app_blue.outputs.alb_zone_app_id, "") : try(data.terraform_remote_state.app_green.outputs.alb_zone_app_id, "")
}


