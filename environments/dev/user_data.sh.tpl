#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# ------------------------------
# Cài đặt gói cần thiết
# ------------------------------
apt-get update -y
apt-get install -y nginx php-fpm php-mysql mysql-client awscli jq curl

# ------------------------------
# Biến nhận từ Terraform
# ------------------------------
REGION="${region}"
DB_HOST="${db_host}"
DB_NAME="pbl4db"

# ------------------------------
# Hàm retry & lấy bí mật từ SSM
# ------------------------------
retry() { # retry <cmd...>
  for i in $(seq 1 10); do
    if "$@"; then return 0; fi
    sleep 3
  done
  return 1
}

fetch_ssm() { # fetch_ssm <param_name>
  local name="$1"
  aws ssm get-parameter --name "$name" --with-decryption --region "$REGION" \
    --query 'Parameter.Value' --output text
}

DB_USER="$(retry fetch_ssm "/pbl4/dev/db_username")"
DB_PASS="$(retry fetch_ssm "/pbl4/dev/db_password")"

# ------------------------------
# Cấu hình Nginx để chạy PHP
# ------------------------------
cat >/etc/nginx/sites-available/default <<'NGX'
server {
  listen 80 default_server;
  server_name _;

  root /var/www/html;
  index index.php index.html;

  # Healthcheck
  location = /health { access_log off; default_type text/plain; return 200 "OK\n"; }

  # PHP via PHP-FPM
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.1-fpm.sock;
  }

  location ~ /\.ht { deny all; }
}
NGX

# ------------------------------
# Bơm ENV vào PHP-FPM (pool www)
# ------------------------------
cat >>/etc/php/8.1/fpm/pool.d/www.conf <<EOF

; === PBL4 DB env (from SSM) ===
env[DB_HOST] = "$DB_HOST"
env[DB_USER] = "$DB_USER"
env[DB_PASS] = "$DB_PASS"
env[DB_NAME] = "$DB_NAME"
EOF

# ------------------------------
# Nội dung web demo
# ------------------------------
cat >/var/www/html/index.html <<'EOF'
<!doctype html><html lang="vi"><head>
<meta charset="utf-8"><title>PBL4 · AWS · Terraform</title>
<style>
 body{font-family:system-ui,sans-serif;background:#0d1b2a;color:#e0e1dd;margin:0;display:flex;min-height:100vh;align-items:center;justify-content:center}
 .card{background:#1b263b;padding:2rem 2.5rem;border-radius:14px;text-align:center}
 h1{margin:.2rem 0;color:#ffb703} a{color:#ffb703}
</style></head>
<body><div class="card">
 <h1>✅ Web đã tự cài bằng cloud-init</h1>
 <p>EC2 (Nginx/PHP-FPM) & RDS (MySQL) ở private.</p>
 <p>Health: <code>/health</code> · DB: <a href="/dbcheck.php">/dbcheck.php</a></p>
</div></body></html>
EOF

# xóa trang mặc định của Ubuntu Nginx (nếu có)
rm -f /var/www/html/index.nginx-debian.html

# reload nginx để nhận file mới
systemctl enable nginx
systemctl restart nginx

cat >/var/www/html/dbcheck.php <<'PHP'
<?php
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASS');
$name = getenv('DB_NAME');

$mysqli = @new mysqli($host, $user, $pass, $name);
if ($mysqli->connect_errno) {
  http_response_code(500);
  echo "<h1>DB CONNECT FAIL</h1><p>($mysqli->connect_errno) $mysqli->connect_error</p>";
} else {
  echo "<h1>DB CONNECT OK</h1>";
}
PHP

chown -R www-data:www-data /var/www/html

# ------------------------------
# Cài CloudWatch Agent từ .deb
# ------------------------------
ARCH="$(dpkg --print-architecture)"  # amd64 hoặc arm64
CWA_DEB_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/$ARCH/latest/amazon-cloudwatch-agent.deb"
curl -fsSL "$CWA_DEB_URL" -o /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get install -f -y

# ------------------------------
# Cấu hình CloudWatch Agent (logs + metrics)
# Dùng __REGION__ làm token; thay bằng $REGION sau
# ------------------------------
install -d /opt/aws/amazon-cloudwatch-agent/etc
cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
{
  "agent": { "region": "__REGION__" },

  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/nginx/access.log", "log_group_name": "/pbl4/dev/nginx/access", "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/nginx/error.log",  "log_group_name": "/pbl4/dev/nginx/error",  "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/php8.1-fpm.log",   "log_group_name": "/pbl4/dev/php-fpm",      "log_stream_name": "{instance_id}" }
        ]
      }
    }
  },

  "metrics": {
    "append_dimensions": { "InstanceId": "$${aws:InstanceId}" },
    "metrics_collected": {
      "cpu":  { "resources": ["*"], "measurement": ["usage_system","usage_user","usage_idle"] },
      "mem":  { "measurement": ["mem_used_percent"] },
      "disk": { "resources": ["*"], "measurement": ["used_percent"] }
    }
  }
}
JSON

sed -i "s/__REGION__/$${REGION}/g" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# ------------------------------
# Khởi động dịch vụ
# ------------------------------
systemctl enable php8.1-fpm
systemctl restart php8.1-fpm

systemctl enable nginx
systemctl restart nginx

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Gợi ý: đảm bảo file này là LF (không phải CRLF)
