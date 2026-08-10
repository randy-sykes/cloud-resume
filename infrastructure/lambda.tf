data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/lambda/cloud_resume_visitors/lambda_function.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

resource "aws_lambda_function" "site" {
  architectures                        = ["x86_64"]
  code_signing_config_arn              = null
  description                          = null
  source_code_hash                     = filebase64sha256("${path.module}/../backend/lambda/cloud_resume_visitors/lambda_function.py")
  filename                             = data.archive_file.lambda_zip.output_path
  function_name                        = var.lambda_function_name
  handler                              = "lambda_function.lambda_handler"
  kms_key_arn                          = null
  layers                               = []
  memory_size                          = 128
  package_type                         = "Zip"
  publish                              = null
  publish_to                           = null
  region                               = var.crc_region
  replace_security_groups_on_destroy   = null
  replacement_security_group_ids       = null
  reserved_concurrent_executions       = -1
  role                                 = aws_iam_role.site.arn
  runtime                              = "python3.15"
  skip_destroy                         = false
  source_kms_key_arn                   = null
  tags                                 = {}
  tags_all                             = {}
  timeout                              = 3
  use_resource_timeout_for_propagation = null
  ephemeral_storage {
    size = 512
  }
  logging_config {
    application_log_level = null
    log_format            = "Text"
    log_group             = "/aws/lambda/${var.lambda_function_name}"
    system_log_level      = null
  }
  tracing_config {
    mode = "PassThrough"
  }
}
