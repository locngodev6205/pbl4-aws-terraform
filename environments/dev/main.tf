terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.region }

locals {
  tags = {
    project = var.project
    env     = var.env
  }
}

# Tự động tìm AMI Ubuntu mới nhất
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID của Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Lấy thông tin về tài khoản AWS hiện tại (như Account ID)
# Chúng ta đã có khối này trong module IAM, nhưng nó cần được khai báo lại
# ở đây vì đây là một "root module" riêng biệt.
data "aws_caller_identity" "me" {}

# Tải public key từ máy local lên AWS để tạo Key Pair
resource "aws_key_pair" "team" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Tạo SSM Parameter để lưu trữ thông tin đăng nhập RDS
resource "aws_ssm_parameter" "db_user" {
  name  = "/pbl4/dev/db_username"
  type  = "SecureString"
  value = var.db_username
}

resource "aws_ssm_parameter" "db_pass" {
  name  = "/pbl4/dev/db_password"
  type  = "SecureString"
  value = var.db_password
}

# Tạo SNS Topic để nhận cảnh báo
# Sử dụng SNS để gửi email cảnh báo khi có sự cố
resource "aws_sns_topic" "alarms" {
  name = "pbl4-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# EC2: CPU cao
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "pbl4-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  dimensions          = { InstanceId = module.compute.instance_id }
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

# EC2: Status Check Failed
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "pbl4-ec2-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  dimensions          = { InstanceId = module.compute.instance_id }
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

# RDS: Free storage thấp
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "pbl4-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 1000000000 # ~1GB
  dimensions          = { DBInstanceIdentifier = "pbl4-rds" }
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

# --- BẮT ĐẦU LẮP RÁP ---

module "vpc" {
  source               = "../../modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  tags                 = { project = var.project, env = var.env }
}

module "security" {
  source            = "../../modules/security"
  vpc_id            = module.vpc.vpc_id
  allow_http_cidr   = "0.0.0.0/0"
  allow_https_cidr  = "0.0.0.0/0"
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  tags              = { project = var.project, env = var.env }
}

module "db" {
  source                 = "../../modules/db"
  subnet_group_name      = module.vpc.db_subnet_group
  vpc_security_group_ids = [module.security.db_sg_id]
  db_name                = "pbl4db"
  username               = var.db_username
  password               = var.db_password
  tags                   = { project = var.project, env = var.env }
}

module "compute" {
  source                      = "../../modules/compute"
  ami_id                      = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnet_id
  security_group_ids          = [module.security.web_sg_id]
  key_name                    = aws_key_pair.team.key_name
  user_data_replace_on_change = true
  iam_instance_profile        = module.iam.instance_profile_name

  # Đây là dòng "ma thuật": nó đọc file .tpl, thay thế các biến,
  # và truyền kịch bản hoàn chỉnh vào cho EC2.
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    region  = var.region
    db_host = module.db.endpoint
  })

  tags = { project = var.project, env = var.env }
}

module "iam" {
  source = "../../modules/iam"
  region = var.region
  tags   = { project = var.project, env = var.env }
}

# --- HỆ THỐNG KIỂM TOÁN (AUDIT LOGGING) VỚI CLOUDTRAIL ---

# 1. Tạo một S3 Bucket an toàn để lưu trữ logs của CloudTrail
resource "aws_s3_bucket" "trail" {
  # Tên bucket phải là duy nhất trên toàn cầu, nên chúng ta thêm Account ID và Region vào
  bucket        = "pbl4-cloudtrail-${data.aws_caller_identity.me.account_id}-${var.region}"
  force_destroy = true # Cho phép xóa bucket dễ dàng khi destroy
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Tạo một "Giấy phép" (Policy) cho phép dịch vụ CloudTrail được ghi file vào Bucket này
data "aws_iam_policy_document" "trail_bucket_policy" {
  statement {
    sid       = "AWSCloudTrailWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail.arn}/AWSLogs/${data.aws_caller_identity.me.account_id}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket_policy.json
}

# 3. Tạo "Hệ thống Camera" (Trail) và chỉ định nơi lưu "băng ghi hình"
resource "aws_cloudtrail" "this" {
  name                          = "pbl4-main-trail"
  s3_bucket_name                = aws_s3_bucket.trail.id
  is_multi_region_trail         = true # Ghi lại hoạt động ở tất cả các region
  include_global_service_events = true
  enable_log_file_validation    = true

  # Chỉ định loại sự kiện cần ghi lại
  event_selector {
    read_write_type           = "All" # Ghi lại cả hành động đọc và ghi
    include_management_events = true
  }

  # Đảm bảo Policy của Bucket được tạo xong trước khi tạo Trail
  depends_on = [aws_s3_bucket_policy.trail]

  tags = local.tags
}