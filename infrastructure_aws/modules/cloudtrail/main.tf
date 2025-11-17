resource "aws_cloudtrail" "cloudtrail" {
  name                       = "${var.project_name}-cloudtrail"
  s3_bucket_name             = aws_s3_bucket.cloudtrail_s3.id
  kms_key_id                 = aws_kms_key.cloudtrail_kms_key.arn # CloudTrail sẽ dùng AWS KMS Key để mã hóa log trước khi lưu S3.
  enable_log_file_validation = true # SHA-256 hash để tạo digest files
    # Log file không bị sửa
    # Không bị xóa một phần
    # Không bị fake log

  is_multi_region_trail      = true # ghi log từ tất cả các region
  enable_logging             = true # Bật / tắt việc ghi log

}
 
# Tạo s3 bucket để lưu log CloudTrail
resource "aws_s3_bucket" "cloudtrail_s3" {
  bucket        = "${var.project_name}-cloudtrail-bucket"
  force_destroy = true # xóa bucket cùng với nội dung bên trong khi destroy
}




# đây là cơ chế kiểu cũ (trước khi có Block Public Access)
# resource "aws_s3_bucket_acl" "s3_bucket" {
#   bucket = aws_s3_bucket.cloudtrail_s3.id

#   acl = "private" # Owner bucket mới có quyền đọc ghi
# }

# Block Public Access settings for this bucket
resource "aws_s3_bucket_public_access_block" "pub_access" {
  bucket                  = aws_s3_bucket.cloudtrail_s3.id
  block_public_acls       = true # Chặn các ACL mới có giá trị công khai, không cho phép người khác truy cập, xem được
  block_public_policy     = true # Bỏ qua mọi ACL public (cũ hoặc mới)
  ignore_public_acls      = true # Chặn bạn tạo policy mới kiểu public
  restrict_public_buckets = true # Chặn Policy cũ + mới, chặn cross-account
}


resource "aws_s3_bucket_policy" "cloudtrail_s3_policy" {
  bucket = aws_s3_bucket.cloudtrail_s3.id
  policy = data.aws_iam_policy_document.cloudtrail_s3_policy.json
}

data "aws_iam_policy_document" "cloudtrail_s3_policy" {
  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.cloudtrail_s3.arn}"]
    actions   = ["s3:GetBucketAcl"] # CloudTrail được phép đọc ACL của bucket

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn" # Chỉ trail đúng tên này mới được phép
      values   = ["arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-cloudtrail"]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.cloudtrail_s3.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    actions   = ["s3:PutObject"] # CloudTrail được phép ghi log vào bucket

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn" # Chỉ trail đúng tên này mới được phép
      values   = ["arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-cloudtrail"]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}





data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cloudtrail_kms_key" {
  description         = "KMS key for cloudtrail"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_policy.json

}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/cloudtrail_kms"
  target_key_id = aws_kms_key.cloudtrail_kms_key.key_id
}


# KMS KEY POLICY
data "aws_iam_policy_document" "kms_policy" {
  # Allow root users full management access to key
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    sid       = "Allow CloudTrail to encrypt logs"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-cloudtrail"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }
  statement {
    sid       = "Allow CloudTrail to describe key"
    effect    = "Allow"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
  statement {
    sid    = "Allow principals in the account to decrypt log files"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:ReEncryptFrom"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }
  statement {
    sid       = "Allow alias creation during setup"
    effect    = "Allow"
    actions   = ["kms:CreateAlias"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ec2.${var.aws_region}.amazonaws.com"]
    }
  }
  statement {
    sid    = "Enable cross account log decryption"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:ReEncryptFrom"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}
