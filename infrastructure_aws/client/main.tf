# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name         = local.current_workspace
  vpc_id               = local.vpc_id
  external_web_alb_sg_id            = local.external_web_alb_sg_id
  # external_app_alb_sg_id   = module.security.external_app_alb_sg_id
  public_subnet_ids    = local.public_subnet_ids
  private_web_subnet_ids = local.private_web_subnet_ids
  # sns_topic_arn        = aws_sns_topic.alarms_topic.arn
}

# ASG Module
module "asg" {
  source = "./modules/asg"

  project_name              = local.current_workspace
  region                    = local.aws_region
  web_sg_id                 = local.web_sg_id
  # app_sg_id                 = local.app_sg_id
  private_web_subnet_ids    = local.private_web_subnet_ids
  # private_app_subnet_ids    = module.vpc.private_app_subnet_ids
  web_target_group_arn      = module.alb.web_target_group_arn
  # app_target_group_arn      = module.alb.app_target_group_arn

  app_dns_name          = var.app_dns_name
  image_tag                 = var.image_tag

  ec2_instance_profile_name = local.ec2_ecr_instance_profile_name

  # Key pair for EC2 instances (optional)
  key_pair_name = local.key_pair_name
}