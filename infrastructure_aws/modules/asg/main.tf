# ASG Module Configuration for Web Tier

resource "aws_launch_template" "web" {
  name          = "${var.project_name}-web-lt"
  image_id      = var.web_ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.web_sg_id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sed -i "s/update-me/${var.internal_alb_dns_name}/g" /etc/nginx/nginx.conf
              sudo systemctl start nginx
              cd /usr/share/nginx/html
              sudo git clone https://github.com/ajitinamdar-tech/three-tier-architecture-aws.git
              mv /usr/share/nginx/html/three-tier-architecture-aws/frontend/* /usr/share/nginx/html/
              sudo rm -rf /usr/share/nginx/html/three-tier-architecture-aws
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-web-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-web-volume"
    }
  }

  lifecycle { 
    create_before_destroy = true # Tạo resource trước khi xóa resource cũ 
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity # Số lượng instance khi khoi tạo
  vpc_zone_identifier  = var.private_web_subnet_ids # Các subnet để triển khai ASG

  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [var.web_target_group_arn]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }
}

# Similarly, for App Tier ASG

resource "aws_launch_template" "app" {
  name          = "${var.project_name}-app-lt"
  image_id      = var.app_ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo systemctl start httpd
              cd /var/www/html
              sudo git clone https://github.com/ajitinamdar-tech/three-tier-architecture-aws.git

              # Copy thư mục api
              sudo mkdir api
              sudo mv /var/www/html/three-tier-architecture-aws/backend/api/* /var/www/html/api/

              # Copy thư mục database
              sudo mkdir database
              sudo mv /var/www/html/three-tier-architecture-aws/database/* /var/www/html/database/

              sudo rm -rf /var/www/html/three-tier-architecture-aws
              sed -i "s/update-me-host/${var.db_host}/g" /var/www/html/api/db_connection.php
              sed -i "s/update-me-username/${var.db_username}/g" /var/www/html/api/db_connection.php
              sed -i "s/update-me-password/${var.db_password}/g" /var/www/html/api/db_connection.php

              mysql -h ${var.db_host} -u ${var.db_username} -p${var.db_password} < /var/www/html/database/database_setup.sql
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-app-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-app-asg"
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.private_app_subnet_ids

  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [var.app_target_group_arn]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-asg"
    propagate_at_launch = true
  }
}
