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
