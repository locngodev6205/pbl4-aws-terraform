# NACL hoạt động ở tầng 4 (Transport Layer)

# NACL cho pubilc subnet
resource "aws_network_acl" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-public-nacl"
  }
}

# internet -> External ALB: 80
resource "aws_network_acl_rule" "public_inbound_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 10
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

# internet -> External ALB: 443
resource "aws_network_acl_rule" "public_inbound_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 20
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

# internet -> External ALB / NACL: 1024-65535 (giúp app & web tải gói)
resource "aws_network_acl_rule" "public_inbound_ephemeral_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 30
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# Outbound
# External ALB -> Web EC2: 80
resource "aws_network_acl_rule" "public_outbound_http_web" {
  count          = length(var.web_private_subnet_cidrs)
  network_acl_id = aws_network_acl.public.id
  rule_number = 110 + count.index
  egress = true
  protocol = "tcp"
  rule_action = "allow"
  cidr_block     = var.web_private_subnet_cidrs[count.index]
  from_port = 80
  to_port = 80
}

# External ALB -> internet: 1024-65535
resource "aws_network_acl_rule" "public_outbound_ephemeral_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 120
  egress = true
  protocol = "tcp"
  rule_action = "allow"
  cidr_block = "0.0.0.0/0"
  from_port = 1024
  to_port = 65535
}

# NAT -> internet: 80 (giúp app & web tải gói)
resource "aws_network_acl_rule" "public_outbound_http_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 130
  egress = true
  protocol = "tcp"
  rule_action = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port = 80
  to_port = 80
}

# NAT -> internet: 443 (giúp app & web tải gói)
resource "aws_network_acl_rule" "public_outbound_https_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 140
  egress = true
  protocol = "tcp"
  rule_action = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port = 443
  to_port = 443
}

resource "aws_network_acl_association" "public" {
  count          = length(var.public_subnet_ids)
  network_acl_id = aws_network_acl.public.id
  subnet_id      = var.public_subnet_ids[count.index]
}


#=============== Private Web Subnets ===============

resource "aws_network_acl" "web_private" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-web-private-nacl"
  }
}

# INBOUND RULES
# External ALB -> Web EC2: 80
resource "aws_network_acl_rule" "web_inbound_http" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 10 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" // không có sẽ lag khhi save
  from_port      = 80
  to_port        = 80
}

# App EC2 -> Web EC2: 1024-65535
resource "aws_network_acl_rule" "web_inbound_ephemeral_app" {
  count          = length(var.app_private_subnet_cidrs)
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 20 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_private_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

# NAT -> Web EC2: 1024-65535 (giúp app & web tải gói)
resource "aws_network_acl_rule" "web_inbound_ephemeral_nat" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 30 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" // không có sẽ lag khi save
  from_port      = 1024
  to_port        = 65535
}


# OUTBOUND RULES

# Web EC2 -> App EC2: 80
# resource "aws_network_acl_rule" "web_outbound_app" {
#   count          = length(var.app_private_subnet_cidrs)
#   network_acl_id = aws_network_acl.web_private.id
#   rule_number    = 105 + count.index
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = var.app_private_subnet_cidrs[count.index]
#   from_port      = 80 // Port api app
#   to_port        = 80 // Thay đổi
# }

# Web EC2 -> App EC2: ephemeral port
# resource "aws_network_acl_rule" "web_outbound_ephemeral_app" {
#   count          = length(var.app_private_subnet_cidrs)
#   network_acl_id = aws_network_acl.web_private.id
#   rule_number    = 110 + count.index
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = var.app_private_subnet_cidrs[count.index]
#   // Có thể một trong các port trùng với port BE (chỉnh lại sau)
#   from_port      = 1024
#   to_port        = 65535
# }

# Web EC2 -> External ALB: 1024-65535
# Web EC2 -> NAT: ephemeral (giúp app & web tải gói)
resource "aws_network_acl_rule" "web_outbound_ephemeral_nat" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 120 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" // không có sẽ lag khi save
  from_port      = 1024
  to_port        = 65535
}


# Web EC2 -> NAT: 80 (giúp app & web tải gói)
resource "aws_network_acl_rule" "web_outbound_http_nat" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 130 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" // không có sẽ lag khi save
  from_port      = 80
  to_port        = 80
}

# Web EC2 -> NAT: 443 (giúp app & web tải gói)
resource "aws_network_acl_rule" "web_outbound_https_nat" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 140 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0" // không có sẽ lag khi save
  from_port      = 443
  to_port        = 443
}

# Web Private NACL - DNS outbound
# resource "aws_network_acl_rule" "web_outbound_dns" {
#   count          = length(var.public_subnet_cidrs)
#   network_acl_id = aws_network_acl.web_private.id
#   rule_number    = 150 + count.index
#   egress         = true
#   protocol       = "udp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 53
#   to_port        = 53
# }

# Associate với Web Subnets
resource "aws_network_acl_association" "web_private" {
  count          = length(var.private_web_subnet_ids)
  network_acl_id = aws_network_acl.web_private.id
  subnet_id      = var.private_web_subnet_ids[count.index]
}

#============= App private subnet =============

# 
resource "aws_network_acl" "app_private" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-app-private-nacl"
  }
}

# INBOUND
# App Private NACL - ICMP từ Internal ALB (web subnet)
# resource "aws_network_acl_rule" "app_inbound_icmp_alb" {
#   count          = length(var.web_private_subnet_cidrs)
#   network_acl_id = aws_network_acl.app_private.id
#   rule_number    = 5 + count.index
#   egress         = false
#   protocol       = "icmp"
#   rule_action    = "allow"
#   cidr_block     = var.web_private_subnet_cidrs[count.index]
#   from_port      = 0
#   to_port        = 0
#   icmp_type      = -1
#   icmp_code      = -1
# }

# Web EC2 -> App EC2: 80
resource "aws_network_acl_rule" "app_inbound_web" {
  count          = length(var.web_private_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 10 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.web_private_subnet_cidrs[count.index]
  from_port      = 80 // Port api app
  to_port        = 80 // Thay đổi
}

# Web EC2 -> App EC2: 8080
resource "aws_network_acl_rule" "app_inbound_ephemeral_web" {
  count          = length(var.web_private_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 20 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.web_private_subnet_cidrs[count.index]
  from_port      = 1024 // Port api app
  to_port        = 65535 // Thay đổi
}

# RDS -> App EC2: 1024-65535
resource "aws_network_acl_rule" "app_inbound_ephemeral_rds" {
  count          = length(var.db_private_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 30 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_private_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

# NAT -> App EC2: 1024-65535 (giúp app & web tải gói)
resource "aws_network_acl_rule" "app_inbound_ephemeral_nat" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 40 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# OUTBOUND

# App EC2 -> RDS: 3306
resource "aws_network_acl_rule" "app_outbound_rds" {
  count          = length(var.db_private_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 110 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_private_subnet_cidrs[count.index]
  from_port      = 3306 // mysql
  to_port        = 3306
}

# App EC2 -> Web EC2: 1024-65535
resource "aws_network_acl_rule" "app_outbound_ephemeral_web" {
  count          = length(var.web_private_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 120 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.web_private_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

# App Private NACL - Internal ALB trong web subnet
# resource "aws_network_acl_rule" "app_outbound_internal_alb" {
#   count          = length(var.web_private_subnet_cidrs)
#   network_acl_id = aws_network_acl.app_private.id
#   rule_number    = 125 + count.index
#   egress         = true
#   protocol       = "tcp"
#   rule_action    = "allow"
#   cidr_block     = var.web_private_subnet_cidrs[count.index]
#   from_port      = 80
#   to_port        = 80
# }

# App EC2 -> NAT: 80 (giúp app & web tải gói)
resource "aws_network_acl_rule" "app_outbound_http_nat" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 130 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# App EC2 -> NAT: 443 (giúp app & web tải gói)
resource "aws_network_acl_rule" "app_outbound_https_nat" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 140 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# App EC2 -> NAT: ephemeral (giúp app & web tải gói)
resource "aws_network_acl_rule" "app_outbound_ephemeral_nat" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 150 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# App Private NACL - DNS outbound  
# resource "aws_network_acl_rule" "app_outbound_dns" {
#   count          = length(var.public_subnet_cidrs)
#   network_acl_id = aws_network_acl.app_private.id
#   rule_number    = 160 + count.index
#   egress         = true
#   protocol       = "udp"
#   rule_action    = "allow"
#   cidr_block     = "0.0.0.0/0"
#   from_port      = 53
#   to_port        = 53
# }

# Associate với App Subnets
resource "aws_network_acl_association" "app_private" {
  count          = length(var.private_app_subnet_ids)
  network_acl_id = aws_network_acl.app_private.id
  subnet_id      = var.private_app_subnet_ids[count.index]
}

#============ DB private subnet ============

# NACL cho private DB subnet
resource "aws_network_acl" "db_private" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-db-private-nacl"
  }
}

# Inbound
# App EC2 -> RDS: 3306
resource "aws_network_acl_rule" "db_inbound_app" {
  count          = length(var.app_private_subnet_cidrs)
  network_acl_id = aws_network_acl.db_private.id
  rule_number = 10 + count.index
  egress = false
  protocol = "tcp"
  rule_action = "allow"
  cidr_block     = var.app_private_subnet_cidrs[count.index]
  from_port = 3306
  to_port = 3306
}

# Outbound
# RDS -> App EC2: 1024-65535
resource "aws_network_acl_rule" "db_outbound_ephemeral_app" {
  count          = length(var.app_private_subnet_cidrs)
  network_acl_id = aws_network_acl.db_private.id
  rule_number    = 110 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_private_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

# Associate với DB Subnets
resource "aws_network_acl_association" "db_private" {
  count          = length(var.private_db_subnet_ids)
  network_acl_id = aws_network_acl.db_private.id
  subnet_id      = var.private_db_subnet_ids[count.index]
}