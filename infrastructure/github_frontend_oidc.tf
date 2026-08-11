resource "aws_iam_role" "github_actions_frontend_deploy" {
  name = "github-actions-frontend-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:randy-sykes@12013518/cloud-resume@1323392838:environment:production"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "frontend_s3_bucket-access" {
  name = "frontend-deploy-s3-bucket-access"
  role = aws_iam_role.github_actions_frontend_deploy.name
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:ListBucket"]
          Resource = "arn:aws:s3:::${var.crc_s3_bucket}"
          }, {
          Effect   = "Allow"
          Action   = ["s3:PutObject", "s3:DeleteObject"]
          Resource = "arn:aws:s3:::${var.crc_s3_bucket}/*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "frontend_deploy_cloudfront_access" {
  name = "frontend-deploy-cloudfront-access"
  role = aws_iam_role.github_actions_frontend_deploy.name
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
          Resource = aws_cloudfront_distribution.site.arn
          }, {
          Effect   = "Allow"
          Action   = ["cloudfront:ListDistributions"]
          Resource = "*"
        }
      ]
    }
  )
}