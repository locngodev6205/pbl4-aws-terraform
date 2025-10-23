#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- Cài đặt các gói cần thiết ---
apt-get update -y
apt-get install -y nginx php-fpm php-mysql mysql-client

# --- Cấu hình Nginx để "nói chuyện" với PHP ---
cat >/etc/nginx/sites-available/default <<'NGX'
server {
  listen 80 default_server;
  server_name _;
  root /var/www/html;
  index index.php index.html;

  location = /health { access_log off; default_type text/plain; return 200 "OK\n"; }

  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.1-fpm.sock;
  }

  location ~ /\.ht { deny all; }
}
NGX

# --- "Bơm" các biến môi trường vào PHP-FPM (Phiên bản đã sửa lỗi) ---
# Dùng 'cat >> ...' để ghi thêm vào cuối file cấu hình mặc định của PHP
cat >>/etc/php/8.1/fpm/pool.d/www.conf <<EOF

; === PBL4 DB env (auto-added by cloud-init) ===
env[DB_HOST] = "${db_host}"
env[DB_USER] = "${db_user}"
env[DB_PASS] = "${db_pass}"
env[DB_NAME] = "${db_name}"
EOF

# --- Tạo nội dung web ---
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

# --- Cấp quyền và khởi động lại dịch vụ ---
chown -R www-data:www-data /var/www/html
systemctl enable php8.1-fpm
systemctl restart php8.1-fpm
systemctl enable nginx
systemctl restart nginx