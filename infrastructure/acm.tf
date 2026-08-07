resource "aws_acm_certificate" "site" {
  certificate_authority_arn = null
  certificate_body          = null
  certificate_chain         = null
  domain_name               = var.domain_name
  early_renewal_duration    = null
  key_algorithm             = "RSA_2048"
  private_key               = null # sensitive
  private_key_wo            = null
  private_key_wo_version    = null
  region                    = "us-east-1"
  subject_alternative_names = [var.domain_name]
  tags                      = {}
  tags_all                  = {}
  validation_method         = "DNS"
  options {
    certificate_transparency_logging_preference = "ENABLED"
    export                                      = "DISABLED"
  }
}
