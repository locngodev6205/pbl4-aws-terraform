# ------- ALB Outputs -------
output "alb_app_arn" {
  value = module.alb.alb_app_arn

}

output "alb_app_dns_name" {
  value = module.alb.alb_app_dns_name
}

output "app_target_group_arn" {
  value = module.alb.app_target_group_arn
}

output "workspace_name" {
  value = local.current_workspace
}