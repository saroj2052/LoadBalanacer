provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "hello_lambda.py"
  output_path = "hello_lambda.zip"
}

resource "aws_iam_role" "role" {
  name = "myrole"

  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"

  # assume_role_policy = jsonencode({
  #   Version = "2012-10-17"
  #   Statement = [
  #     {
  #       Action = "sts:AssumeRole"
  #       Effect = "Allow"
  #       Sid    = ""
  #       Principal = {
  #         Service = "lambda.amazonaws.com"
  #       }
  #     },
  #   ]
  # })
}

resource "aws_lambda_function" "lambda" {
  filename      = "hello_lambda.zip"
  function_name = "lambda"
  role          = aws_iam_role.role.arn
  handler       = "hello_lambda.lambda_handler"
  runtime       = "python3.9"
#   filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"

#   source_code_hash = filebase64sha256("lambda.zip")
  environment {
    variables = {
      greeting = "Hello"
    }
  }
}

resource "aws_apigatewayv2_api" "lambda_api" {
  name                       = "v2-http-api"
  protocol_type              = "HTTP"
  
}
resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id = aws_apigatewayv2_api.lambda_api.id
  name   = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  integration_uri = aws_lambda_function.lambda.invoke_arn
  passthrough_behavior ="WHEN_NO_MATCH"
}
resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /{proxy+}"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*/*"
}


# # API Gateway
# resource "aws_api_gateway_rest_api" "api" {
#   name = "sarojapi"
# }

# resource "aws_api_gateway_resource" "resource" {
#   path_part   = "resource"
#   parent_id   = aws_api_gateway_rest_api.api.root_resource_id
#   rest_api_id = aws_api_gateway_rest_api.api.id
# }

# resource "aws_api_gateway_method" "method" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.resource.id
#   http_method   = "GET"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "integration" {
#   rest_api_id             = aws_api_gateway_rest_api.api.id
#   resource_id             = aws_api_gateway_resource.resource.id
#   http_method             = aws_api_gateway_method.method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.lambda.invoke_arn
# }

# # Lambda





data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

