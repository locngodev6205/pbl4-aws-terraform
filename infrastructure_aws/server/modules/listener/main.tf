# Target Group
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-app-tg" 
  port     = var.port
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
    Name = "${var.project_name}-app-tg"
  }
}

# Listener for Internal ALB
resource "aws_lb_listener" "external_app_http" {
  load_balancer_arn = var.external_app_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}