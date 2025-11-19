# ALB Module Configuration

resource "aws_lb" "external_web" {
  name               = "${var.project_name}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.external_web_alb_sg_id]
  subnets            = var.public_subnet_ids  

  enable_deletion_protection = false # cho phép xóa ALB khi cần thiết

  drop_invalid_header_fields = true # từ chối các yêu cầu với header không hợp lệ

  tags = {
    Name = "${var.project_name}-web-alb"
  }
}

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
  load_balancer_arn = aws_lb.external_web.arn
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