terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = var.region }

/* Tuần 3–4 sẽ mở các module này:
module "vpc"      { source = "../../modules/vpc" }
module "security" { source = "../../modules/security" }
module "compute"  { source = "../../modules/compute" }
module "db"       { source = "../../modules/db" }
*/

data "aws_caller_identity" "me" {}
data "aws_region" "current" {}

output "whoami"   { value = data.aws_caller_identity.me.arn }
output "region"   { value = data.aws_region.current.name }
