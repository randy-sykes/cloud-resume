resource "aws_iam_role" "site" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  description           = null
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "cloud_resume_visitors-role-gct6bp2g"
  path                  = "/service-role/"
  permissions_boundary  = null
  tags                  = {}
  tags_all              = {}
}

resource "aws_iam_role_policy" "site" {
  name = "visitor-counter-dynamodb-access"
  policy = jsonencode({
    Statement = [{
      Action   = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
      Effect   = "Allow"
      Resource = "arn:aws:dynamodb:us-east-1:969473017687:table/cloud-resume-visitors"
    }]
    Version = "2012-10-17"
  })
  role = aws_iam_role.site.name
}

resource "aws_iam_role_policy_attachment" "site" {
  policy_arn = "arn:aws:iam::969473017687:policy/service-role/AWSLambdaBasicExecutionRole-201580af-d419-4328-bdf5-ec770897a0a7"
  role       = aws_iam_role.site.name
}


