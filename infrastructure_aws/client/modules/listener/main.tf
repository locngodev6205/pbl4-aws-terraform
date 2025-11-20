resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
    matcher             = "200"
  }


  tags = {
    Name = "${var.project_name}-web-tg"
  }
}

resource "aws_lb_listener" "external_web_http" {
  load_balancer_arn = var.external_web_arn
  port              = var.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# resource "aws_lb_listener" "external_web_https" {
#   load_balancer_arn = aws_lb.external_web.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   # certificate_arn   = var.

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
# }