terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.region }

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

# Tải public key từ máy local lên AWS để tạo Key Pair
resource "aws_key_pair" "team" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
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

  # Đây là dòng "ma thuật": nó đọc file .tpl, thay thế các biến,
  # và truyền kịch bản hoàn chỉnh vào cho EC2.
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    db_host = module.db.endpoint
    db_user = var.db_username
    db_pass = var.db_password
    db_name = "pbl4db"
  })

  tags = { project = var.project, env = var.env }
}

# --- ĐỊNH NGHĨA CÁC KẾT QUẢ ĐẦU RA ---
output "web_public_ip" {
  value       = module.compute.public_ip
  description = "Public IP address of the EC2 instance."
}
output "web_url" {
  value       = "http://${module.compute.public_ip}"
  description = "URL to access the web server."
}
output "rds_endpoint" {
  value       = module.db.endpoint
  description = "The connection endpoint for the RDS instance."
}