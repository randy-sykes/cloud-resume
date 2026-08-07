terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.8.0"
    }
  }
  backend "s3" {
    bucket       = "randy-sykes-terraform-state"
    key          = "cloud-resume/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "archive" {
  # Configuration options
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
