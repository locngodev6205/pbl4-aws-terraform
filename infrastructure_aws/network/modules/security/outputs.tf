output "external_web_alb_sg_id" {
  value = aws_security_group.external_web_alb.id
}

output "external_app_alb_sg_id" {
  value = aws_security_group.external_app_alb.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "web_sg_id" {
  value = aws_security_group.web.id
}

output "app_sg_id" {
  value = aws_security_group.app.id
}
