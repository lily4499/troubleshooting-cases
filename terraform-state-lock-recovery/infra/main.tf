locals {
  common_tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

# Demo resource to create/modify safely during apply
resource "aws_s3_bucket" "demo" {
  bucket_prefix = "${var.project}-${var.env}-"
  tags          = local.common_tags
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

output "demo_bucket_name" {
  value = aws_s3_bucket.demo.bucket
}
