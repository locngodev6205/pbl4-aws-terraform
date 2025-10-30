#!/bin/bash
set -e

# --- Update hệ thống ---
sudo dnf update -y

# --- Cài đặt Nginx & CloudWatch Agent ---
sudo dnf install -y nginx amazon-cloudwatch-agent
sudo systemctl enable nginx

# --- Tạo cấu hình Nginx Reverse Proxy ---
sudo tee /etc/nginx/conf.d/opencart_proxy.conf >/dev/null <<'PROXY_CONFIG'
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass          http://update-me;   # sẽ được thay bằng internal ALB DNS
        proxy_set_header    Host $host;
        proxy_set_header    X-Real-IP $remote_addr;
        proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto $scheme;
    }
}
PROXY_CONFIG

# --- Thay internal ALB DNS bằng biến Terraform ---
sudo sed -i "s|update-me|${var.internal_alb_dns_name}|g" /etc/nginx/conf.d/opencart_proxy.conf

# --- Khởi động Nginx ---
sudo systemctl restart nginx

# --- CloudWatch Agent cấu hình logs ---
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json >/dev/null <<'AGENT_CONFIG'
{
  "agent": { "run_as_user": "root" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/nginx/access.log", "log_group_name": "${var.project_name}-web-access", "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/nginx/error.log",  "log_group_name": "${var.project_name}-web-error",  "log_stream_name": "{instance_id}" }
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
