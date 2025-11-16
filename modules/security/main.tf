resource "aws_security_group" "web" {
  name        = "pbl-web-sg"
  description = "Allow web + restricted SSH"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "pbl-web-sg" })
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic from web tier"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = var.allow_http_cidr
  description       = "Allow inbound HTTP from Internet for web server"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.allow_https_cidr
  description       = "Allow inbound HTTPS from Internet for web server"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each          = toset(var.allowed_ssh_cidrs)
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
  description       = "Allow inbound SSH from restricted CIDRs for web server"
}

resource "aws_security_group" "db" {
  name        = "pbl-db-sg"
  description = "Allow DB from web_sg only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "pbl-db-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "db_3306" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  description                  = "Allow inbound MySQL from web tier"
}