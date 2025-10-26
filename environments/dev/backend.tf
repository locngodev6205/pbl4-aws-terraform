terraform {
  backend "s3" {
    bucket         = "pbl4-tfstate-636192785351-ap-southeast-1" # THAY BẰNG TÊN BUCKET CỦA BẠN
    key            = "pbl4/dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "pbl4-tf-lock" # THAY BẰNG TÊN TABLE CỦA BẠN
    encrypt        = true
  }
}