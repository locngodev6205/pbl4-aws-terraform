output "alb_web_arn" {
  value = aws_lb.external_web.arn
}

output "alb_web_dns_name" {
  value = aws_lb.external_web.dns_name
}

output "web_target_group_arn" {
  value = aws_lb_target_group.web.arn
}

output "alb_zone_id" {
  value = aws_lb.external_web.zone_id
}