output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_web_subnet_ids" {
  value = slice(aws_subnet.private[*].id, 0, 2)
}

output "private_app_subnet_ids" {
  value = slice(aws_subnet.private[*].id, 2, 4)
}

# output "private_db_subnet_ids" {
#   value = slice(aws_subnet.private[*].id, 4, 6)
# }