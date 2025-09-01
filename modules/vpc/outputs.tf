output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_id" { value = aws_subnet.public.id }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
output "db_subnet_group" { value = aws_db_subnet_group.db.name }