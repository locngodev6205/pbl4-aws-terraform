# ------- ALB Outputs -------
output "alb_app_arn" {
  value = module.alb.alb_app_arn

}

output "alb_app_dns_name" {
  value = module.alb.alb_app_dns_name
}

output "alb_zone_app_id" {
  value = module.alb.alb_zone_app_id
}

output "app_target_group_arn" {
  value = module.alb.app_target_group_arn
}

output "workspace_name" {
  value = local.current_workspace
}