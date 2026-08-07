variable "cloudflare_api_token" {
  sensitive   = true
  type        = string
  description = "API Token for access to Cloudflare for randy-sykes.me"

  validation {
    condition     = length(var.cloudflare_api_token) >= 40
    error_message = "The API Token should be 40 characters long"
  }

  validation {
    condition     = startswith(var.cloudflare_api_token, "cfat_")
    error_message = "The provided token is not a valid Cloudflare token that starts with 'cfat_'"
  }
}

variable "cloudflare_zone_id" {
  type        = string
  description = "This is the Zone ID for the domain that is used for this project"
  default     = "25304e979b99a07f655ff173aa60498c"

  validation {
    condition     = length(var.cloudflare_zone_id) >= 15
    error_message = "Zone ID should be longer than 15 characters"
  }
}

variable "crc_s3_bucket" {
  type        = string
  description = "S3 bucket name for the Cloud Resume Challenge I've been working on"
  default     = "randy-sykes.me"

  validation {
    condition     = length(var.crc_s3_bucket) > 10
    error_message = "The standard name for this bucket is at least 10 characters long"
  }
}

variable "crc_region" {
  type        = string
  description = "AWS Region for this config"
  default     = "us-east-1"
}

variable "domain_name" {
  type        = string
  description = "Domain name you are using to setup the site"
  default     = "randy-sykes.me"

  validation {
    condition     = length(var.domain_name) > 5
    error_message = "This should be the domain name for the site you are setting up and I expect it to be longer the 5 characters."
  }
}

variable "dynamodb_table_name" {
  type    = string
  default = "cloud-resume-visitors"
}

variable "lambda_function_name" {
  type    = string
  default = "cloud_resume_visitors"
}

variable "api_gateway_name" {
  type    = string
  default = "cloud-resume-api"
}

variable "api_gateway_stage_name" {
  type    = string
  default = "resume-visitors"
}