resource "aws_db_instance" "this" {
  identifier     = "pbl4-rds"
  engine         = var.engine
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username
  password = var.password

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_subnet_group_name   = var.subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids

  publicly_accessible = var.publicly_accessible
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = true
  apply_immediately       = true

  tags = merge(var.tags, { Name = "pbl4-rds" })

  storage_encrypted = true

  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  # backup_retention_period đã có, chúng ta sẽ đặt giá trị cho nó ở .tfvars
}