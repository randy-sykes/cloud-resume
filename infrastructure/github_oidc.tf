# Add for use in the resource for cloudfront
data "aws_caller_identity" "current" {}


# OIDC setup
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

# Role permissions
resource "aws_iam_role" "github_actions_plan" {
  name = "github-actions-plan"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:randy-sykes@12013518/cloud-resume@1323392838:pull_request"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "github_actions_apply" {
  name = "github-actions-apply"

  assume_role_policy = jsonencode(
    {
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
          }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:randy-sykes@12013518/cloud-resume@1323392838:ref:refs/heads/main"
            }
          }
        }
      ]
    }
  )
}

# State permissions
resource "aws_iam_role_policy" "plan-state" {
    name = "plan-state-access"
    role = aws_iam_role.github_actions_plan.name
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Action    = ["s3:GetObject"]
          Resource = "arn:aws:s3:::randy-sykes-terraform-state/cloud-resume/terraform.tfstate"
        }, {
          Effect    = "Allow"
          Action    = ["s3:PutObject", "s3:DeleteObject"]
          Resource = "arn:aws:s3:::randy-sykes-terraform-state/cloud-resume/terraform.tfstate.tflock"
        }
      ]
    }
  ) 
}

resource "aws_iam_role_policy" "apply-state" {
    name = "apply-state-access"
    role = aws_iam_role.github_actions_apply.name
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Action    = ["s3:GetObject", "s3:PutObject"]
          Resource = "arn:aws:s3:::randy-sykes-terraform-state/cloud-resume/terraform.tfstate"
        }, {
          Effect    = "Allow"
          Action    = ["s3:PutObject", "s3:DeleteObject"]
          Resource = "arn:aws:s3:::randy-sykes-terraform-state/cloud-resume/terraform.tfstate.tflock"
        }
      ]
    }
  ) 
}

# S3 permissions
resource "aws_iam_role_policy" "plan_s3_bucket" {
    name = "plan-s3-bucket-access"
    role = aws_iam_role.github_actions_plan.name
    policy = jsonencode(
      {
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Action    = ["s3:GetBucketPolicy", "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration", "s3:GetBucketPublicAccessBlock"]
          Resource = "arn:aws:s3:::${var.crc_s3_bucket}"
        }, {
          Effect    = "Allow"
          Action    = ["s3:GetObject"]
          Resource = "arn:aws:s3:::${var.crc_s3_bucket}/*"
        }
      ]
    }
  ) 
}

resource "aws_iam_role_policy" "apply_s3_bucket" {
    name = "apply-s3-bucket-access"
    role = aws_iam_role.github_actions_apply.name
    policy = jsonencode(
      {
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Action    = ["s3:GetBucketPolicy", "s3:PutBucketPolicy", "s3:PutBucketVersioning", "s3:GetBucketVersioning", "s3:GetEncryptionConfiguration", "s3:GetBucketPublicAccessBlock"]
          Resource = "arn:aws:s3:::${var.crc_s3_bucket}"
        }, {
          Effect    = "Allow"
          Action    = ["s3:GetObject", "s3:PutObject"]
          Resource = "arn:aws:s3:::${var.crc_s3_bucket}/*"
        }
      ]
    }
  ) 
}

# Cloudfront permissions
resource "aws_iam_role_policy" "plan_cloudfront" {
  name = "plan-cloundfront-access"
  role = aws_iam_role.github_actions_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["cloudfront:GetOriginAccessControl"]
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/${aws_cloudfront_origin_access_control.site.id}"
      },{
        Effect = "Allow"
        Action = ["cloudfront:GetDistribution", "cloudfront:ListTagsForResource"]
        Resource = aws_cloudfront_distribution.site.arn
      },
    ]
  })
}

resource "aws_iam_role_policy" "apply_cloudfront" {
  name = "apply-cloundfront-access"
  role = aws_iam_role.github_actions_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["cloudfront:GetOriginAccessControl", "cloudfront:UpdateOriginAccessControl"]
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:origin-access-control/${aws_cloudfront_origin_access_control.site.id}"
      },{
        Effect = "Allow"
        Action = ["cloudfront:GetDistribution", "cloudfront:UpdateDistribution", "cloudfront:ListTagsForResource"]
        Resource = aws_cloudfront_distribution.site.arn
      },
    ]
  })
}

# ACM permissions
resource "aws_iam_role_policy" "plan_acm" {
  name = "plan-acm-access"
  role = aws_iam_role.github_actions_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["acm:DescribeCertificate", "acm:ListTagsForCertificate"]
        Resource = aws_acm_certificate.site.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "apply_acm" {
  name = "apply-acm-access"
  role = aws_iam_role.github_actions_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["acm:DescribeCertificate", "acm:ListTagsForCertificate", "acm:RequestCertificate", "acm:DeleteCertificate"]
        Resource = "arn:aws:acm:us-east-1:${data.aws_caller_identity.current.account_id}:certificate/*"
      }
    ]
  })
}

# DynamoDB permissions
resource "aws_iam_role_policy" "plan_dynamodb" {
  name = "plan-dynamodb-access"
  role = aws_iam_role.github_actions_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:DescribeTable", "dynamodb:DescribeContinuousBackups", "dynamodb:DescribeTimeToLive", "dynamodb:ListTagsOfResource"]
        Resource = aws_dynamodb_table.site.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "apply_dynamodb" {
  name = "apply-dynamodb-access"
  role = aws_iam_role.github_actions_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # Left out the CreateTable/DeleteTable since this table already has deletion_protection_enabled and prevent_destroy.
        # A full rebuild should go through manual/local apply instead of CI.
        Action = ["dynamodb:DescribeTable", "dynamodb:DescribeContinuousBackups", "dynamodb:DescribeTimeToLive", "dynamodb:ListTagsOfResource", "dynamodb:UpdateTable", "dynamodb:UpdateContinuousBackups", "dynamodb:UpdateTimeToLive", "dynamodb:TagResource", "dynamodb:UntagResource"]
        Resource = aws_dynamodb_table.site.arn
      }
    ]
  })
}

# Lambda permissions
resource "aws_iam_role_policy" "plan_lambda" {
  name = "plan-lambda-access"
  role = aws_iam_role.github_actions_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:GetFunction", "lambda:GetPolicy", "lambda:ListVersionsByFunction", "lambda:ListTags"]
        Resource = aws_lambda_function.site.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "apply_lambda" {
  name = "apply-lambda-access"
  role = aws_iam_role.github_actions_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:GetFunction", "lambda:GetPolicy", "lambda:ListVersionsByFunction", "lambda:ListTags", "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration", "lambda:RemovePermission", "lambda:AddPermission"]
        Resource = aws_lambda_function.site.arn
      }
    ]
  })
}

# API Gateway permissions
resource "aws_iam_role_policy" "plan_api_gateway" {
  name = "plan-api-gateway-access"
  role = aws_iam_role.github_actions_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["apigateway:GET"]
        Resource = "arn:aws:apigateway:us-east-1::/restapis/${aws_api_gateway_rest_api.site.id}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "apply_api_gateway" {
  name = "apply-api-gateway-access"
  role = aws_iam_role.github_actions_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["apigateway:GET"]
        Resource = "arn:aws:apigateway:us-east-1::/restapis/${aws_api_gateway_rest_api.site.id}/*"
      },{
        Effect = "Allow"
        Action = ["apigateway:POST"]
        Resource = "arn:aws:apigateway:us-east-1::/restapis/${aws_api_gateway_rest_api.site.id}/*"
      },{
        Effect = "Allow"
        Action = ["apigateway:PATCH"]
        Resource = "arn:aws:apigateway:us-east-1::/restapis/${aws_api_gateway_rest_api.site.id}/*"
      },{
        Effect = "Allow"
        Action = ["apigateway:PUT"]
        Resource = "arn:aws:apigateway:us-east-1::/restapis/${aws_api_gateway_rest_api.site.id}/*"
      },{
        Effect = "Allow"
        Action = ["apigateway:DELETE"]
        Resource = "arn:aws:apigateway:us-east-1::/restapis/${aws_api_gateway_rest_api.site.id}/*"
      }
    ]
  })
}

# IAM permissions
resource "aws_iam_role_policy" "plan_iam_access" {
  name = "plan-iam-access"
  role = aws_iam_role.github_actions_plan.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["iam:GetRole", "iam:GetRolePolicy", "iam:ListAttachedRolePolicies"]
        Resource = [aws_iam_role.site.arn, aws_iam_role.github_actions_plan.arn, aws_iam_role.github_actions_apply.arn]

      }, {
        Effect = "Allow"
        Action = ["iam:ListOpenIDConnectProviders"]
        Resource = "*"
      }, {
        Effect = "Allow"
        Action = ["iam:GetOpenIDConnectProvider"]
        Resource = aws_iam_openid_connect_provider.github_actions.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "apply_iam_access" {
  name = "apply-iam-access"
  role = aws_iam_role.github_actions_apply.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["iam:GetRole", "iam:GetRolePolicy", "iam:ListAttachedRolePolicies"]
        Resource = [aws_iam_role.site.arn, aws_iam_role.github_actions_plan.arn, aws_iam_role.github_actions_apply.arn]

      }, {
        Effect = "Allow"
        Action = ["iam:ListOpenIDConnectProviders"]
        Resource = "*"
      }, {
        Effect = "Allow"
        Action = ["iam:GetOpenIDConnectProvider"]
        Resource = aws_iam_openid_connect_provider.github_actions.arn
      }, {
        Effect = "Allow"
        Action = ["iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:AttachRolePolicy", "iam:DetachRolePolicy"]
        Resource = aws_iam_role.site.arn
      }, {
        Effect = "Allow"
        Action = ["iam:UpdateRole", "iam:UpdateAssumeRolePolicy", "iam:TagRole", "iam:UntagRole"]
        Resource = aws_iam_role.site.arn
      }
    ]
  })
}