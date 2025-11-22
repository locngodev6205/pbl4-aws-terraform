
data "aws_route53_zone" "main" {
  name         = "locngodev.click"       # <-- đổi theo domain của bạn
  private_zone = false
}


resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "web"
  type    = "A"

  alias {
    name                   = local.active_alb_web_dns_name
    zone_id                = local.active_alb_web_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app"
  type    = "A"

  alias {
    name                   = local.active_alb_app_dns_name
    zone_id                = local.active_alb_app_zone_id
    evaluate_target_health = true
  }
}