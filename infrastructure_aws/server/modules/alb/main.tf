# Internal ALB for web-app communication
resource "aws_lb" "external_app" {
  name               = "${var.project_name}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.external_app_alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  drop_invalid_header_fields = true

  tags = {
    Name = "${var.project_name}-app-alb"
  }
}

# Target Group for App Tier
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
  load_balancer_arn = aws_lb.external_app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}