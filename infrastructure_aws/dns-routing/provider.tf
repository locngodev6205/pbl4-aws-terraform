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
      name = "pbl4-dns-routing" 
    } 
  } 
}

provider "aws" {
  region = var.aws_region
}
