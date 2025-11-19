resource "aws_launch_template" "app" {
  name          = "${var.project_name}-app-lt"
  image_id      = var.app_ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.app_sg_id]

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

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

              # Login ECR (app)
              aws ecr get-login-password --region ${var.region} \
                | docker login --username AWS --password-stdin ${split("/", var.app_ecr_image)[0]}

              # Pull app image
              docker pull ${var.app_ecr_image}:${var.image_tag}

              # Stop/remove old container nếu có
              docker stop quickshow-backend || true
              docker rm quickshow-backend || true

              cat >/home/ubuntu/app.env <<EOT
                MONGODB_URI=mongodb+srv://locngodev:locngodev@cluster0.lzbpi06.mongodb.net
                CLERK_PUBLISHABLE_KEY=pk_test_bmVhdC1tdXN0YW5nLTYwLmNsZXJrLmFjY291bnRzLmRldiQ
                CLERK_SECRET_KEY=sk_test_BKqSVDbURojWdFwTlSsNz1rT90RirNpBcyBQvTLmUN

                INNGEST_EVENT_KEY=bqO8l8FOA6dLMaEgo5HSoi3YL2ihQjGovKGvbEaeGDmtbeetOiLKITRylvgSu8bV_MaYHg1AiSBU_o_9yiDSbw
                INNGEST_SIGNING_KEY=signkey-prod-2c0a5ef59be2613cfcf894b381faaf405301c1965ff712fd07a090b4d752ed10

                TMDB_API_KEY=eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJiNTJmZTg0NjMzOWQ1NTNjNTQ0MTk2YzNjM2U5ZDcwNSIsIm5iZiI6MTc1MjkxNDMxMC43NjMsInN1YiI6IjY4N2I1OTg2YjQ1YjNmYTQ4NTE2OThmZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.YM8D4tffvGdheWsN3kYeyLnKfka8hPCpXDjgU2WHuCE

                STRIPE_PUBLISHABLE_KEY=pk_test_51Rn9rCQ92B7ZVzTAHozVN66ZRbcARVvHNSSUjsWjTZAMLhTA3FLvEvPo9AIQjdMQuh0m1hQx9WSduF1A7phnIf0000bgDELO2N
                STRIPE_SECRET_KEY=sk_test_51Rn9rCQ92B7ZVzTArCJRHpgTEpq7Y7YfOxzgLuIcJ0djYFC2qq5X98SaZpojhI31KIK6yVhwtad536VMrWPxHEGM003EoH8gLF
                STRIPE_WEBHOOK_SECRET=whsec_Zx7PoOGUlt7NHbSdV09RLfVDxah2rHXd

                SENDER_EMAIL=62205ngovanloc@gmail.com
                SMTP_USER=92aa4c001@smtp-brevo.com
                SMTP_PASS=xsmtpsib-f0cd80336e5a170be3c28b75e297a8bc8c68ee5c7a1d65fe6af649c3f996ee02-AZv3LSqFyS3j3cyz

              EOT


              docker run -d --name quickshow-backend --env-file /home/ubuntu/app.env -p 80:3000 ${var.app_ecr_image}:${var.image_tag}
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