# Terraform configuration for Three-Tier Architecture

# CloudTrail Module
module "cloudtrail" {
  source = "./modules/cloudtrail"

  project_name = var.project_name
  aws_region   = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name      = var.project_name
  availability_zones = var.availability_zones

  public_subnet     = var.public_subnet_cidrs
  private_subnet    = var.private_subnet_cidrs

  depends_on = [module.cloudtrail]
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id

  depends_on = [module.cloudtrail]
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
  # sns_topic_arn        = aws_sns_topic.alarms_topic.arn

  depends_on = [module.cloudtrail]
}

# ASG Module
module "asg" {
  source = "./modules/asg"

  project_name              = var.project_name
  region                    = var.aws_region
  web_sg_id                 = module.security.web_sg_id
  app_sg_id                 = module.security.app_sg_id
  private_web_subnet_ids    = module.vpc.private_web_subnet_ids
  private_app_subnet_ids    = module.vpc.private_app_subnet_ids
  web_target_group_arn      = module.alb.web_target_group_arn
  app_target_group_arn      = module.alb.app_target_group_arn

  internal_alb_dns_name     = module.alb.internal_alb_dns_name
  image_tag                 = "v1.0.7"
  
  db_username               = var.db_username
  db_password               = var.db_password

  ec2_instance_profile_name = aws_iam_instance_profile.ec2_ecr_instance_profile.name

  # Key pair for EC2 instances (optional)
  key_pair_name = var.key_pair_name

  depends_on = [module.cloudtrail]
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

  depends_on = [module.cloudtrail]
}




# --- SNS Topic for CloudWatch Alarms ---

# Tạo một kênh thông báo SNS
# resource "aws_sns_topic" "alarms_topic" {
#   name = "${var.project_name}-alarms-topic"
# }

# Đăng ký email
# resource "aws_sns_topic_subscription" "email_subscription" {
#   topic_arn = aws_sns_topic.alarms_topic.arn
#   protocol  = "email"
#   endpoint  = "62205ngovanloc@gmail.com" 
# }
