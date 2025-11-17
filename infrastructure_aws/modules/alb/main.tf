# ALB Module Configuration

resource "aws_lb" "external" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids  

  enable_deletion_protection = false # cho phép xóa ALB khi cần thiết

  drop_invalid_header_fields = true # từ chối các yêu cầu với header không hợp lệ

  tags = {
    Name = "${var.project_name}-alb"
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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.external.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   # certificate_arn   = var.

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
# }

# Internal ALB for web-app communication
resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  drop_invalid_header_fields = true

  tags = {
    Name = "${var.project_name}-internal-alb"
  }
}

# Target Group for App Tier
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-app-tg" 
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
    Name = "${var.project_name}-app-tg"
  }
}

# Listener for Internal ALB
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# --- CloudWatch Alarm for ALB 5xx Errors ---
# resource "aws_cloudwatch_metric_alarm" "public_alb_5xx_errors" {
#   alarm_name          = "${var.project_name}-public-alb-high-5xx-errors-alarm"
  
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 1
  
#   # Chỉ số cần theo dõi: Số lượng lỗi 5xx từ các máy chủ đích (Target)
#   metric_name         = "HTTPCode_Target_5XX_Count" 
  
#   # Dịch vụ cung cấp chỉ số là ApplicationELB
#   namespace           = "AWS/ApplicationELB"
  
#   # Thu thập và tính toán mỗi 5 phút (300 giây)
#   period              = 300
  
#   # Cách tính toán: Tính tổng số lỗi
#   statistic           = "Sum" 
  
#   # Ngưỡng: Nếu có từ 5 lỗi trở lên trong 5 phút thì kích hoạt
#   threshold           = 5    

#   # Chỉ định chính xác tài nguyên cần theo dõi: Public ALB của chúng ta
#   dimensions = {
#     LoadBalancer = aws_lb.external.arn_suffix
#   }

#   alarm_description = "Kích hoạt khi Public ALB có quá nhiều lỗi 5xx từ server"
  
#   # Hành động khi có lỗi: Gửi thông báo đến SNS Topic
#   alarm_actions     = [var.sns_topic_arn]
  
#   # Hành động khi hết lỗi (trạng thái chuyển từ ALARM về OK): Cũng gửi thông báo
#   ok_actions        = [var.sns_topic_arn]
# }
