output "active_color" {
  description = "Màu hiện đang active (blue/green)"
  value       = var.active_color
}

output "active_alb_dns_name" {
  description = "DNS của ALB đang được route bởi Route53"
  value       = local.active_alb_dns_name
}

output "active_alb_zone_id" {
  description = "Zone ID của ALB đang được Route53 trỏ tới"
  value       = local.active_alb_zone_id
}

output "domain_endpoint" {
  description = "Domain endpoint để truy cập frontend"
  value       = aws_route53_record.web.fqdn
}
