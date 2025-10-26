data "aws_caller_identity" "me" {}
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "pbl4-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
  tags               = var.tags
}

# --- BỘ QUY TẮC SSM ĐÃ ĐƯỢC SIẾT CHẶT ---

# Sử dụng `locals` để xây dựng động các ARN của SSM Parameter
# Điều này giúp code sạch sẽ và dễ bảo trì.
locals {
  param_arns = [
    "arn:aws:ssm:${var.region}:${data.aws_caller_identity.me.account_id}:parameter/pbl4/dev/db_username",
    "arn:aws:ssm:${var.region}:${data.aws_caller_identity.me.account_id}:parameter/pbl4/dev/db_password",
  ]
}

# Tạo ra "nội dung" của bộ quy tắc mới
data "aws_iam_policy_document" "ssm_read_restrict" {
  # Statement 1: Chỉ cho phép đọc ĐÚNG 2 parameter đã được định nghĩa ở trên
  statement {
    sid       = "AllowReadSpecificSSMParameters"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = local.param_arns
  }

  # Statement 2: Cho phép giải mã KMS, nhưng với điều kiện
  statement {
    sid     = "AllowKMSDecryptViaSSM"
    actions = ["kms:Decrypt"]
    # Vẫn dùng "*" vì chúng ta không biết trước KMS key nào sẽ được dùng
    resources = ["*"]

    # Điều kiện này cực kỳ quan trọng: chỉ cho phép giải mã KHI yêu cầu
    # đến từ chính dịch vụ SSM trong đúng region này.
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.region}.amazonaws.com"]
    }
  }
}

# Tạo ra "bộ quy tắc" (Policy) từ nội dung ở trên
resource "aws_iam_policy" "ssm_read_restrict" {
  name   = "pbl4-ssm-read-restrict"
  policy = data.aws_iam_policy_document.ssm_read_restrict.json
}

# "Ghim" bộ quy tắc mới này lên "Thẻ nhân viên" (IAM Role)
resource "aws_iam_role_policy_attachment" "attach_ssm_read_restrict" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ssm_read_restrict.arn
}

# Quyền đọc SSM (SecureString cần kms:Decrypt)
# data "aws_iam_policy_document" "ssm_read" {
#   statement {
#     actions   = ["ssm:GetParameter","ssm:GetParameters"]
#     resources = ["*"]
#   }
#   statement {
#     actions   = ["kms:Decrypt"]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "ssm_read" {
#   name   = "pbl4-ssm-read"
#   policy = data.aws_iam_policy_document.ssm_read.json
# }

# Quyền CloudWatch Logs/Metrics
data "aws_iam_policy_document" "cw_agent" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

# resource "aws_iam_policy" "cw_agent" {
#   name   = "pbl4-cw-agent"
#   policy = data.aws_iam_policy_document.cw_agent.json
# }

# SSM Session Manager (tiện để SSH-less, nếu muốn)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# resource "aws_iam_role_policy_attachment" "attach_ssm_read" {
#   role       = aws_iam_role.ec2.name
#   policy_arn = aws_iam_policy.ssm_read.arn
# }

# resource "aws_iam_role_policy_attachment" "attach_cw_agent" {
#   role       = aws_iam_role.ec2.name
#   policy_arn = aws_iam_policy.cw_agent.arn
# }

resource "aws_iam_instance_profile" "ec2" {
  name = "pbl4-ec2-instance-profile"
  role = aws_iam_role.ec2.name
}

# Gắn bộ quy tắc có sẵn của AWS cho CloudWatch Agent
# Bộ quy tắc này chứa tất cả các quyền cần thiết.
resource "aws_iam_role_policy_attachment" "attach_cw_agent_managed" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}