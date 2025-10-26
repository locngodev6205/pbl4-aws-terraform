# --- ĐỊNH NGHĨA CÁC KẾT QUẢ ĐẦU RA ---
output "web_public_ip" {
  value       = module.compute.public_ip
  description = "Public IP address of the EC2 instance."
}
output "web_url" {
  value       = "http://${module.compute.public_ip}"
  description = "URL to access the web server."
}
output "rds_endpoint" {
  value       = module.db.endpoint
  description = "The connection endpoint for the RDS instance."
}

# (tuỳ chọn, nếu muốn quan sát thêm)
output "cloudtrail_bucket" {
  description = "S3 bucket storing CloudTrail logs."
  value       = aws_s3_bucket.trail.bucket
}

output "sns_topic_arn" {
  description = "SNS topic for alarms."
  value       = aws_sns_topic.alarms.arn
}