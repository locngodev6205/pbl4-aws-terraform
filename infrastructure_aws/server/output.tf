# ------- listener Outputs -------

output "workspace_name" {
  value = local.current_workspace
}

output "alb_app_dns_name" {
  value = local.alb_app_dns_name
}