output "alb_app_arn" {
  value = aws_lb.external_app.arn
}

output "alb_app_dns_name" {
  value = aws_lb.external_app.dns_name
}

output "alb_zone_app_id" {
  value = aws_lb.external_app.zone_id
}

output "app_target_group_arn" {
  value = aws_lb_target_group.app.arn
}