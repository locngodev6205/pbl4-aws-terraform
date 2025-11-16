region  = "ap-southeast-1"
project = "pbl4-aws-terraform"
env     = "dev"

vpc_cidr             = "10.10.0.0/16"
public_subnet_cidr   = "10.10.1.0/24"
private_subnet_cidrs = ["10.10.2.0/24", "10.10.3.0/24"]
azs                  = ["ap-southeast-1a", "ap-southeast-1b"]

instance_type     = "t3.micro"
allowed_ssh_cidrs = ["171.231.197.75/32", "117.3.54.230/32"]

key_name        = "pbl4-team"
public_key_path = "C:/Users/LEGION/.ssh/pbl4.pub"

alert_email = "dat11022005@gmail.com"

backup_retention_period = 1