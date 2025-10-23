locals {
  user_data_file = try(file(var.user_data_path), "")
}

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = var.iam_instance_profile

  # Ưu tiên dùng user_data dạng chuỗi, nếu không có thì fallback sang file
  user_data                   = coalesce(var.user_data, local.user_data_file)
  user_data_replace_on_change = var.user_data_replace_on_change

  tags = merge(var.tags, { Name = "pbl-web-ec2" })
}

resource "aws_eip" "this" {
  count    = var.allocate_eip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.web.id
  tags     = merge(var.tags, { Name = "pbl-eip" })
}