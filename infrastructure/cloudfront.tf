resource "aws_cloudfront_origin_access_control" "site" {
  description                       = "Created by CloudFront"
  name                              = "oac-${var.domain_name}.s3.us-east-1.amazonaws.com-msfe6ya8tv8"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_distribution" "site" {
  aliases             = [var.domain_name]
  anycast_ip_list_id  = null
  comment             = null
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  staging             = false
  tags = {
    Name = var.domain_name
  }
  tags_all = {
    Name = var.domain_name
  }
  wait_for_deployment = true
  web_acl_id          = "arn:aws:wafv2:us-east-1:969473017687:global/webacl/CreatedByCloudFront-7216976b/b04e74ca-f320-45a1-8f8a-5d2c97d0b2d8"
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    default_ttl                = 0
    field_level_encryption_id  = null
    max_ttl                    = 0
    min_ttl                    = 0
    origin_request_policy_id   = null
    realtime_log_config_arn    = null
    response_headers_policy_id = null
    smooth_streaming           = false
    target_origin_id           = "${var.domain_name}.s3.us-east-1.amazonaws.com-msfe6axslhg"
    trusted_key_groups         = []
    trusted_signers            = []
    viewer_protocol_policy     = "redirect-to-https"
    grpc_config {
      enabled = false
    }
  }
  origin {
    connection_attempts         = 3
    connection_timeout          = 10
    domain_name                 = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id    = aws_cloudfront_origin_access_control.site.id
    origin_id                   = "${var.domain_name}.s3.us-east-1.amazonaws.com-msfe6axslhg"
    origin_path                 = null
    response_completion_timeout = 0
  }
  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.site.arn
    cloudfront_default_certificate = false
    iam_certificate_id             = null
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}