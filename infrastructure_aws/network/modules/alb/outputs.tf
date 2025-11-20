output "alb_web_arn" {
  value = aws_lb.external_web.arn
}

output "alb_web_dns_name" {
  value = aws_lb.external_web.dns_name
}

output "alb_app_arn" {
  value = aws_lb.external_app.arn
}

output "alb_app_dns_name" {
  value = aws_lb.external_app.dns_name
}

