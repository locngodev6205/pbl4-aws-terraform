# infrastructure_aws/bastion.tf

# Tìm AMI Amazon Linux 2 mới nhất một cách tự động
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Tạo EC2 Instance cho Bastion Host
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro" # Free tier eligible
  
  # Đặt Bastion vào một trong các PUBLIC subnets
  subnet_id     = module.vpc.public_subnet_ids[0]

  # Gán Public IP cho nó
  associate_public_ip_address = true

  # Gắn Security Group đã tạo
  vpc_security_group_ids = [module.security.bastion_sg_id]

  # Chỉ định Key Pair để bạn có thể SSH vào
  key_name = var.key_pair_name

  tags = {
    Name = "${var.project_name}-bastion-host"
  }
}

# Output ra địa chỉ IP Public của Bastion Host
output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host"
  value       = aws_instance.bastion.public_ip
}