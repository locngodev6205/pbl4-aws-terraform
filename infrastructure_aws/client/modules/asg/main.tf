# ASG Module Configuration for Web Tier



resource "aws_launch_template" "web" {
  name          = "${var.project_name}-web-lt"
  image_id      = var.web_ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.web_sg_id]

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  # metadata_options {
  #   http_endpoint               = "enabled" # Bật endpoint IMDSv2
  #   http_tokens                 = "required" # Yêu cầu token cho các yêu cầu IMDSv2
  #   http_put_response_hop_limit = 2
  # }


    user_data = base64encode(<<-EOF
              #!/bin/bash
              set -xe

              # Update
              apt-get update -y

              # Install basic tools
              apt-get install -y unzip software-properties-common

              # Install Docker
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
              unzip /tmp/awscliv2.zip -d /tmp
              /tmp/aws/install

              # Login ECR (web)
              aws ecr get-login-password --region ${var.region} \
                | docker login --username AWS --password-stdin ${split("/", var.web_ecr_image)[0]}

              # Pull web image
              docker pull ${var.web_ecr_image}:${var.image_tag}

              # Stop/remove old container nếu có
              docker stop quickshow-frontend || true
              docker rm quickshow-frontend || true

              docker run -d --name quickshow-frontend -e APP_ALB_DNS=${var.app_dns_name} -p 80:80 ${var.web_ecr_image}:${var.image_tag}
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