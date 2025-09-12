locals { user_data = try(file(var.user_data_path), "") }

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = true
  user_data                   = local.user_data
  tags                        = merge(var.tags, { Name = "pbl-web-ec2" })
}

resource "aws_eip" "this" {
  count    = var.allocate_eip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.web.id
  tags     = merge(var.tags, { Name = "pbl-eip" })
}