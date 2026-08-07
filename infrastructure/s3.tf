resource "aws_s3_bucket" "site" {
  bucket              = var.crc_s3_bucket
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
  region              = var.crc_region
  tags                = {}
  tags_all            = {}
}

resource "aws_s3_bucket_public_access_block" "site" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.site.id
  ignore_public_acls      = true
  region                  = var.crc_region
  restrict_public_buckets = true
  skip_destroy            = null
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Id = "PolicyForCloudFrontPrivateContent"
    Statement = [{
      Action = "s3:GetObject"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = "arn:aws:cloudfront::969473017687:distribution/E1C5AKF4U9KHFR"
        }
      }
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Resource = "${aws_s3_bucket.site.arn}/*"
      Sid      = "AllowCloudFrontServicePrincipal"
    }]
    Version = "2008-10-17"
  })
  region = var.crc_region
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  mfa    = null
  region = var.crc_region
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Disabled"
  }
}

resource "aws_s3_object" "api_url" {
  bucket       = aws_s3_bucket.site.id
  key          = "api_url.txt"
  content      = aws_api_gateway_stage.site.invoke_url
  content_type = "text/plain"
}