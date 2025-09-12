terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.region }

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID của Canonical (nhà phát hành Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "team" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

module "vpc" {
  source               = "../../modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  tags                 = { project = var.project, env = var.env }
}

module "security" {
  source            = "../../modules/security"
  vpc_id            = module.vpc.vpc_id
  allow_http_cidr   = "0.0.0.0/0"
  allow_https_cidr  = "0.0.0.0/0"
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  tags              = { project = var.project, env = var.env }
}

module "compute" {
  source             = "../../modules/compute"
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_id
  security_group_ids = [module.security.web_sg_id]
  key_name           = aws_key_pair.team.key_name
  allocate_eip       = true
  user_data_path     = "${path.module}/user_data.sh" # tuần 4 sẽ cài web
  tags               = { project = var.project, env = var.env }
}

output "web_public_ip" { value = module.compute.public_ip }
output "web_url" { value = "http://${module.compute.public_ip}" }
output "vpc_id" { value = module.vpc.vpc_id }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "db_subnet_group" { value = module.vpc.db_subnet_group }