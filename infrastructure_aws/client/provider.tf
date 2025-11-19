terraform { 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  cloud { 
    organization = "locngodev" 

    workspaces { 
      tags = ["pbl4-client"]
    } 
  } 
}

provider "aws" {
  region = var.aws_region
}
