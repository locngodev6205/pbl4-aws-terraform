# modules/security/main.tf

# ===================================================================
# 1. TẠO CÁC SECURITY GROUP "TRỐNG"
# ===================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Public ALB"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_security_group" "internal_alb" {
  name        = "${var.project_name}-internal-alb-sg"
  description = "Security group for Internal ALB"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project_name}-internal-alb-sg" }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for Web Tier EC2 instances"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project_name}-web-sg" }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for App Tier EC2 instances"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project_name}-app-sg" }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for RDS instances"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project_name}-db-sg" }
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.project_name}-bastion-sg" }
}


# ===================================================================
# 2. TẠO CÁC LUẬT (RULES) RIÊNG LẺ VÀ GẮN VÀO GROUP
# ===================================================================

# --- Luật cho Public ALB ---
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from anywhere"
}
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from anywhere"
}
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
}

# --- Luật cho Web Tier ---
resource "aws_security_group_rule" "web_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80 # Hoặc 0 nếu bạn muốn cho phép cả 80/443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.web.id
  description              = "Allow HTTP/S from Public ALB"
}
resource "aws_security_group_rule" "web_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"
}

# --- Luật cho Internal ALB ---
resource "aws_security_group_rule" "internal_alb_ingress_from_web" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.internal_alb.id
  description              = "Allow HTTP/S from Web Tier"
}
resource "aws_security_group_rule" "internal_alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.internal_alb.id
  description       = "Allow all outbound traffic"
}

# --- Luật cho App Tier ---
resource "aws_security_group_rule" "app_ingress_from_internal_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow HTTP/S from Internal ALB"
}
resource "aws_security_group_rule" "app_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic"
}

# --- Luật cho Database ---
resource "aws_security_group_rule" "db_ingress_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
  description              = "Allow MySQL from App Tier"
}
# (Bạn có thể thêm luật egress cho DB nếu muốn siết chặt, nhưng egress-all cũng được)

# --- LUẬT CHO BASTION HOST (ĐÃ PHÁ VỠ VÒNG LẶP) ---
resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.my_ip]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow SSH from my IP"
}
resource "aws_security_group_rule" "bastion_egress_ssh_to_web" {
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id # Đây là destination
  security_group_id        = aws_security_group.bastion.id
  description              = "Allow SSH to Web Tier"
}
resource "aws_security_group_rule" "bastion_egress_ssh_to_app" {
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id # Đây là destination
  security_group_id        = aws_security_group.bastion.id
  description              = "Allow SSH to App Tier"
}
resource "aws_security_group_rule" "web_ingress_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.web.id
  description              = "Allow SSH from Bastion"
}
resource "aws_security_group_rule" "app_ingress_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow SSH from Bastion"
}