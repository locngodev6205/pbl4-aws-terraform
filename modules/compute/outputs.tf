output "instance_id" { value = aws_instance.web.id }
output "public_ip" { value = coalesce(try(aws_eip.this[0].public_ip, null), aws_instance.web.public_ip) }