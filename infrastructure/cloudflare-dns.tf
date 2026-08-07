resource "cloudflare_dns_record" "www" {
  comment         = "cloud-resume-entry"
  content         = aws_cloudfront_distribution.site.domain_name
  data            = null
  name            = "www.${var.domain_name}"
  priority        = null
  private_routing = null
  proxied         = false
  settings = {
    flatten_cname = false
    ipv4_only     = false
    ipv6_only     = false
  }
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "apex" {
  comment         = "cloud-resume-entry"
  content         = aws_cloudfront_distribution.site.domain_name
  data            = null
  name            = var.domain_name
  priority        = null
  private_routing = null
  proxied         = false
  settings = {
    flatten_cname = false
    ipv4_only     = false
    ipv6_only     = false
  }
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "acm_validation" {
  comment         = "cloud-resume-entry"
  content         = trimsuffix(one(aws_acm_certificate.site.domain_validation_options).resource_record_value, ".")
  data            = null
  name            = trimsuffix(one(aws_acm_certificate.site.domain_validation_options).resource_record_name, ".")
  priority        = null
  private_routing = null
  proxied         = false
  settings = {
    flatten_cname = false
    ipv4_only     = false
    ipv6_only     = false
  }
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
}
