# Terraform configuration for Three-Tier Architecture

# CloudTrail Module
module "cloudtrail" {
  source = "./modules/cloudtrail"

  project_name = local.current_workspace
  aws_region   = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name      = local.current_workspace
  availability_zones = var.availability_zones

  public_subnet     = var.public_subnet_cidrs
  private_subnet    = var.private_subnet_cidrs

  depends_on = [module.cloudtrail]
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = local.current_workspace
  vpc_id       = module.vpc.vpc_id

  depends_on = [module.cloudtrail]
}
module "nacl" {
  source = "./modules/nacl"

  project_name = local.current_workspace
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_web_subnet_ids = module.vpc.private_web_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  # private_db_subnet_ids = module.vpc.private_db_subnet_ids

  public_subnet_cidrs = var.public_subnet_cidrs
  web_private_subnet_cidrs = slice(var.private_subnet_cidrs, 0, 2)
  app_private_subnet_cidrs = slice(var.private_subnet_cidrs, 2, 4)
  # db_private_subnet_cidrs = slice(var.private_subnet_cidrs, 4, 6)

  depends_on = [module.cloudtrail]
}

# Tạo một ec2 bastion để SSH vào các instance trong private subnet (Web & App)
resource "aws_instance" "bastion" {
  ami                         = var.bastion_ami_id
  instance_type               = var.bastion_instance_type
  subnet_id                   = element(module.vpc.public_subnet_ids, 0)
  vpc_security_group_ids      = [module.security.bastion_sg_id]
  key_name                    = var.key_pair_name

  tags = {
    Name = "${local.current_workspace}-bastion"
  }
  # ip public enable
  associate_public_ip_address = true

  lifecycle { 
    create_before_destroy = true # Tạo resource trước khi xóa resource cũ 
  }
}