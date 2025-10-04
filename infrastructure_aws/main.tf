# Terraform configuration for Three-Tier Architecture

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name      = var.project_name
  availability_zones = var.availability_zones

  public_subnet     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet    = ["10.0.11.0/24", "10.0.12.0/24", "10.0.21.0/24", "10.0.22.0/24", "10.0.31.0/24", "10.0.32.0/24"]
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  alb_sg_id            = module.security.alb_sg_id
  internal_alb_sg_id   = module.security.internal_alb_sg_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_web_subnet_ids = module.vpc.private_web_subnet_ids
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  db_sg_id              = module.security.db_sg_id

  # Required: set these
  db_username = var.db_username
  db_password = var.db_password
}

# ASG Module
module "asg" {
  source = "./modules/asg"

  project_name              = var.project_name
  web_sg_id                 = module.security.web_sg_id
  app_sg_id                 = module.security.app_sg_id
  private_web_subnet_ids    = module.vpc.private_web_subnet_ids
  private_app_subnet_ids    = module.vpc.private_app_subnet_ids
  web_target_group_arn      = module.alb.web_target_group_arn
  app_target_group_arn      = module.alb.app_target_group_arn


  internal_alb_dns_name     = module.alb.internal_alb_dns_name
  
  db_host                   = module.rds.db_endpoint
  db_username               = var.db_username
  db_password               = var.db_password

  # Key pair for EC2 instances (optional)
  key_pair_name = var.key_pair_name
}
