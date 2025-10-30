# Terraform configuration for Three-Tier Architecture

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name      = var.project_name
  availability_zones = var.availability_zones

  public_subnet     = var.public_subnet_cidrs
  private_subnet    = var.private_subnet_cidrs

  flow_log_iam_role_arn = aws_iam_role.vpc_flow_logs_role.arn
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip        = var.my_ip
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

  sns_topic_arn        = aws_sns_topic.alarms_topic.arn
  # certificate_arn      = aws_acm_certificate.cert.arn
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
  db_name                   = module.rds.db_name

  ec2_instance_profile_name = aws_iam_instance_profile.ec2_cloudwatch_agent_instance_profile.name

  # Key pair for EC2 instances (optional)
  key_pair_name = var.key_pair_name
}

module "nacl" {
  source = "./modules/nacl"

  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_web_subnet_ids = module.vpc.private_web_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  private_db_subnet_ids = module.vpc.private_db_subnet_ids

  public_subnet_cidrs = var.public_subnet_cidrs
  web_private_subnet_cidrs = slice(var.private_subnet_cidrs, 0, 2)
  app_private_subnet_cidrs = slice(var.private_subnet_cidrs, 2, 4)
  db_private_subnet_cidrs = slice(var.private_subnet_cidrs, 4, 6)
}

# # --- SNS Topic for CloudWatch Alarms ---

# Tạo một kênh thông báo SNS
resource "aws_sns_topic" "alarms_topic" {
  name = "${var.project_name}-alarms-topic"
  kms_master_key_id = aws_kms_key.sns_key.arn
}

# Đăng ký email
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarms_topic.arn
  protocol  = "email"
  endpoint  = "puppy261205@gmail.com" 
}

# resource "aws_acm_certificate" "cert" {
#   domain_name       = "thuongmaidientu.com"
#   validation_method = "DNS"
# }