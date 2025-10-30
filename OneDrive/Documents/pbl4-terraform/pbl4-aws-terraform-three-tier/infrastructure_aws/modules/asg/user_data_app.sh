#!/bin/bash
set -e

# --- Update hệ thống ---
sudo dnf update -y

# --- Cài đặt Apache, PHP, CloudWatch Agent, unzip, AWS CLI ---
sudo dnf install -y httpd php php-mysqli php-json php-session php-gd php-xml mariadb amazon-cloudwatch-agent unzip aws-cli
sudo systemctl enable httpd

# --- Khởi động Apache ---
sudo systemctl start httpd

# --- Tải OpenCart từ S3 ---
aws s3 cp s3://pbl4-opencart-install-files-cunbien/3.0.4.1-OpenCart.zip /tmp/opencart.zip
sudo unzip /tmp/opencart.zip -d /var/www/html/
sudo rm -f /tmp/opencart.zip

# --- Cấp quyền thư mục ---
sudo chown -R apache:apache /var/www/html
sudo chmod -R 755 /var/www/html

# --- Cấu hình kết nối DB ---
sudo sed -i "s|update-me-host|${var.db_host}|g" /var/www/html/config.php
sudo sed -i "s|update-me-username|${var.db_username}|g" /var/www/html/config.php
sudo sed -i "s|update-me-password|${var.db_password}|g" /var/www/html/config.php

# --- Tạo database schema nếu cần ---
if [ -f /var/www/html/install/opencart.sql ]; then
  mysql -h ${var.db_host} -u ${var.db_username} -p${var.db_password} < /var/www/html/install/opencart.sql || true
fi

# --- CloudWatch Agent cấu hình ---
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json >/dev/null <<'AGENT_CONFIG'
{
  "agent": { "run_as_user": "root" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/httpd/access_log", "log_group_name": "${var.project_name}-app-access", "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/httpd/error_log",  "log_group_name": "${var.project_name}-app-error",  "log_stream_name": "{instance_id}" }
        ]
      }
    }
  }
}
AGENT_CONFIG

# --- Start CloudWatch Agent ---
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
