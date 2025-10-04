# VPC Module Configuration

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name = "${var.project_name}-public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name = "${var.project_name}-private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway in Public Subnet [0]
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# resource "aws_route_table" "private-nat" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gw.id
#   }

#   tags = {
#     Name = "${var.project_name}-private-web-rt"
#   }
# }

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "${var.project_name}-private-app-db-rt"
#   }
# }



# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# resource "aws_route_table_association" "private_web" {
#   count          = 2  # Chỉ 2 subnet đầu tiên
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private_with_nat.id
# }

# resource "aws_route_table_association" "private_app_db" {
#   count          = length(var.private_subnet) - 2  # 4 subnet còn lại
#   subnet_id      = aws_subnet.private[count.index + 2].id  # Bắt đầu từ index 2
#   route_table_id = aws_route_table.private_without_nat.id
# }
