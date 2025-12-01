# iam.tf

# Role for EC2 to assume
resource "aws_iam_role" "ec2_ecr_role" {
  name = "${local.current_workspace}-ec2-ecr-role"

  # Trust policy allowing EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AmazonEC2ContainerRegistryReadOnly policy to the role
resource "aws_iam_role_policy_attachment" "ec2_ecr_policy_attachment" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}



# Policy to allow reading from Secrets Manager
resource "aws_iam_policy" "secrets_manager_read_policy" {
  name        = "${local.current_workspace}-secrets-manager-read-policy"
  description = "Allows reading secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Attach the Secrets Manager read policy to the role
resource "aws_iam_role_policy_attachment" "ec2_secrets_manager_policy_attachment" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}

# Create an Instance Profile to attach the role to EC2 instances
resource "aws_iam_instance_profile" "ec2_ecr_instance_profile" {
  name = "${local.current_workspace}-ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_role.name
}