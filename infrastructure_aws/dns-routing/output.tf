output "active_color" {
  description = "Màu hiện đang active (blue/green)"
  value       = var.active_color
}

output "active_alb_web_dns_name" {
  description = "DNS của ALB đang được route bởi Route53"
  value       = local.active_alb_web_dns_name
}
  
output "active_alb_web_zone_id" {
  description = "Zone ID của ALB đang được Route53 trỏ tới"
  value       = local.active_alb_web_zone_id
}

output "domain_endpoint_web" {
  description = "The DNS name of the web record"
  # Dùng one(...) và [*] để xử lý list
  value       = one(aws_route53_record.web[*].fqdn)
}


output "active_alb_app_dns_name" {
  description = "DNS của ALB App đang được route bởi Route53"
  value       = local.active_alb_app_dns_name
}

output "active_alb_app_zone_id" {
  description = "Zone ID của ALB App đang được Route53 trỏ tới"
  value       = local.active_alb_app_zone_id
}

output "domain_endpoint_app" {
  description = "The DNS name of the app record"
  # Tương tự cho app
  value       = one(aws_route53_record.app[*].fqdn)
}