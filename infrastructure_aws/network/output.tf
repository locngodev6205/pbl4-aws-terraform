# ------- VPC Outputs -------
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "aws_region" {
  value = var.aws_region
}

output "key_pair_name" {
  value = var.key_pair_name
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_web_subnet_ids" {
  value = module.vpc.private_web_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc.private_app_subnet_ids
}
# ------- Security Outputs -------
output "external_web_alb_sg_id" {
  value = module.security.external_web_alb_sg_id
}

output "external_app_alb_sg_id" {
  value = module.security.external_app_alb_sg_id
}

output "bastion_sg_id" {
  value = module.security.bastion_sg_id
}

output "web_sg_id" {
  value = module.security.web_sg_id
}

output "app_sg_id" {
  value = module.security.app_sg_id
}

output "alb_web_arn" {
  value = module.alb.alb_web_arn
}

output "alb_web_dns_name" {
  value = module.alb.alb_web_dns_name
}

output "alb_app_arn" {
  value = module.alb.alb_app_arn
}

output "alb_app_dns_name" {
  value = module.alb.alb_app_dns_name
}


# ------- IAM Outputs -------
output "ec2_ecr_instance_profile_name" {
  value = aws_iam_instance_profile.ec2_ecr_instance_profile.name
}