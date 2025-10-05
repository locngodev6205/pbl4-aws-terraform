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
      name = "pbl4-three-tier-infrastructure" 
    } 
  } 
}

provider "aws" {
  region = "ap-southeast-1"
}
