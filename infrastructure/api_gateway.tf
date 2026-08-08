resource "aws_api_gateway_resource" "count" {
  parent_id   = aws_api_gateway_rest_api.site.root_resource_id
  path_part   = "count"
  region      = var.crc_region
  rest_api_id = aws_api_gateway_rest_api.site.id
}

# __generated__ by Terraform
resource "aws_api_gateway_rest_api" "site" {
  api_key_source               = "HEADER"
  binary_media_types           = []
  body                         = null
  disable_execute_api_endpoint = false
  endpoint_access_mode         = null
  fail_on_warnings             = null
  name                         = var.api_gateway_name
  parameters                   = null
  put_rest_api_mode            = "overwrite"
  region                       = var.crc_region
  security_policy              = "TLS_1_0"
  tags                         = {}
  tags_all                     = {}
  endpoint_configuration {
    ip_address_type = "ipv4"
    types           = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "post" {
  api_key_required     = false
  authorization        = "NONE"
  authorization_scopes = []
  authorizer_id        = null
  http_method          = "POST"
  operation_name       = null
  region               = var.crc_region
  request_models       = {}
  request_parameters   = {}
  request_validator_id = null
  resource_id          = aws_api_gateway_resource.count.id
  rest_api_id          = aws_api_gateway_rest_api.site.id
}

resource "aws_api_gateway_method" "get" {
  api_key_required     = false
  authorization        = "NONE"
  authorization_scopes = []
  authorizer_id        = null
  http_method          = "GET"
  operation_name       = null
  region               = var.crc_region
  request_models       = {}
  request_parameters   = {}
  request_validator_id = null
  resource_id          = aws_api_gateway_resource.count.id
  rest_api_id          = aws_api_gateway_rest_api.site.id
}

resource "aws_api_gateway_integration" "get" {
  cache_key_parameters    = []
  cache_namespace         = aws_api_gateway_resource.count.id
  connection_id           = null
  connection_type         = "INTERNET"
  content_handling        = "CONVERT_TO_TEXT"
  credentials             = null
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  integration_target      = null
  passthrough_behavior    = "WHEN_NO_MATCH"
  region                  = var.crc_region
  request_parameters      = {}
  request_templates       = {}
  resource_id             = aws_api_gateway_resource.count.id
  response_transfer_mode  = "BUFFERED"
  rest_api_id             = aws_api_gateway_rest_api.site.id
  timeout_milliseconds    = 29000
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.site.invoke_arn
}

resource "aws_api_gateway_integration" "post" {
  cache_key_parameters    = []
  cache_namespace         = aws_api_gateway_resource.count.id
  connection_id           = null
  connection_type         = "INTERNET"
  content_handling        = "CONVERT_TO_TEXT"
  credentials             = null
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  integration_target      = null
  passthrough_behavior    = "WHEN_NO_MATCH"
  region                  = var.crc_region
  request_parameters      = {}
  request_templates       = {}
  resource_id             = aws_api_gateway_resource.count.id
  response_transfer_mode  = "BUFFERED"
  rest_api_id             = aws_api_gateway_rest_api.site.id
  timeout_milliseconds    = 29000
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.site.invoke_arn
}

resource "aws_lambda_permission" "apigw_get" {
  action                   = "lambda:InvokeFunction"
  event_source_token       = null
  function_name            = var.lambda_function_name
  function_url_auth_type   = null
  invoked_via_function_url = null
  principal                = "apigateway.amazonaws.com"
  principal_org_id         = null
  qualifier                = null
  region                   = var.crc_region
  source_account           = null
  source_arn               = "${aws_api_gateway_rest_api.site.execution_arn}/*/GET/count"
}

resource "aws_lambda_permission" "apigw_post" {
  action                   = "lambda:InvokeFunction"
  event_source_token       = null
  function_name            = var.lambda_function_name
  function_url_auth_type   = null
  invoked_via_function_url = null
  principal                = "apigateway.amazonaws.com"
  principal_org_id         = null
  qualifier                = null
  region                   = var.crc_region
  source_account           = null
  source_arn               = "${aws_api_gateway_rest_api.site.execution_arn}/*/POST/count"
}

resource "aws_api_gateway_stage" "site" {
  cache_cluster_enabled = false
  cache_cluster_size    = null
  client_certificate_id = null
  deployment_id         = aws_api_gateway_deployment.site.id
  description           = null
  documentation_version = null
  region                = var.crc_region
  rest_api_id           = aws_api_gateway_rest_api.site.id
  stage_name            = var.api_gateway_stage_name
  tags                  = {}
  tags_all              = {}
  variables             = {}
  xray_tracing_enabled  = false
}

resource "aws_api_gateway_deployment" "site" {
  description = null
  region      = var.crc_region
  rest_api_id = aws_api_gateway_rest_api.site.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.count.id,
      aws_api_gateway_method.get.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.get.id,
      aws_api_gateway_integration.post.id,
    ]))
  }
  variables = null

  lifecycle {
    create_before_destroy = true
  }
}
