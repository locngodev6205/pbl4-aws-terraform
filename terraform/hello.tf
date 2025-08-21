# terraform/hello.tf
resource "local_file" "hello" {
  content  = "PBL4-AWS-Terraform - Week 1: Init successful!"
  filename = "${path.module}/hello.txt"
}