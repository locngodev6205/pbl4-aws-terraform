data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
        type = "Service"
        identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "pbl4-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
  tags               = var.tags
}

# Quyền đọc SSM (SecureString cần kms:Decrypt)
data "aws_iam_policy_document" "ssm_read" {
  statement {
    actions   = ["ssm:GetParameter","ssm:GetParameters"]
    resources = ["*"]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm_read" {
  name   = "pbl4-ssm-read"
  policy = data.aws_iam_policy_document.ssm_read.json
}

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

resource "aws_iam_role_policy_attachment" "attach_ssm_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ssm_read.arn
}

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