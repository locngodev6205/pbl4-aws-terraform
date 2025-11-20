# ALB Module
module "listener" {
  source = "./modules/listener"

  project_name         = local.current_workspace
  vpc_id               = local.vpc_id

  external_app_arn     = local.external_app_arn
  port                 = var.port
}

# ASG Module
module "asg" {
  source = "./modules/asg"

  project_name              = local.current_workspace
  region                    = local.aws_region
  # web_sg_id                 = module.security.web_sg_id
  app_sg_id                 = local.app_sg_id
  # private_web_subnet_ids    = module.vpc.private_web_subnet_ids
  private_app_subnet_ids    = local.private_app_subnet_ids
  # web_target_group_arn      = module.listener.web_target_group_arn
  app_target_group_arn      = module.listener.app_target_group_arn

  image_tag                 = var.image_tag

  # db_username               = var.db_username
  # db_password               = var.db_password

  ec2_instance_profile_name = local.ec2_ecr_instance_profile_name
  # Key pair for EC2 instances (optional)
  key_pair_name = local.key_pair_name
}