
data "aws_route53_zone" "main" {
  name         = "locngodev.click"
  private_zone = false
}
resource "aws_route53_record" "web" {
  count = length(local.active_alb_web_dns_name) > 0 ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  
  name    = "web.${data.aws_route53_zone.main.name}"
  
  type    = "A"

  alias {
    name                   = local.active_alb_web_dns_name
    zone_id                = local.active_alb_web_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "app" {
  count = length(local.active_alb_app_dns_name) > 0 ? 1 : 0
  
  zone_id = data.aws_route53_zone.main.zone_id
  
  name    = "app.${data.aws_route53_zone.main.name}"
  
  type    = "A"

  alias {
    name                   = local.active_alb_app_dns_name
    zone_id                = local.active_alb_app_zone_id
    evaluate_target_health = true
  }
}