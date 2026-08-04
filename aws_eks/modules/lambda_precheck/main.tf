# ------------------------------------------------------------------------------
# SECURITY GROUP pour la Lambda (accès à Redis/Valkey dans le VPC)
# ------------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.33.0"
    }
  }
}

data "aws_region" "current" {}
resource "aws_security_group" "lambda_precheck_security_group" {
  name        = "lambda_precheck_security_group"
  description = "Security Group pour la Lambda de Pre-check"
  vpc_id      = var.vpc_id

  tags = {
    Name = "lambda_precheck_security_group"
  }
}

# Règle de sortie (Egress) pour que la Lambda puisse requêter à l'intérieur du VPC
resource "aws_vpc_security_group_egress_rule" "lambda_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.lambda_precheck_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ------------------------------------------------------------------------------
# FONCTION LAMBDA
# ------------------------------------------------------------------------------
resource "aws_lambda_function" "precheck_lambda" {
  filename      = "${path.module}/chunk_precheck.zip"
  function_name = "${var.name_prefix}-precheck-lambda"
  role          = var.lambda_role_arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 15

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_precheck_security_group.id]
  }

  layers = [
    "arn:aws:lambda:${data.aws_region.current.id}:177933569100:layer:AWS-Parameters-and-Secrets-Lambda-Extension:17"
  ]

  environment {
    variables = {
      REDIS_HOST       = var.redis_endpoint
      REDIS_PORT       = "6379"
      REDIS_SECRET_ARN = var.redis_secret_arn 
      DYNAMODB_TABLE   = var.dynamodb_table_name
    }
  }

  tags = var.tags
}	


# ------------------------------------------------------------------------------
# API GATEWAY HTTP
# ------------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.name_prefix}-video-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Request-ID"]
    max_age       = 3600
  }
}

# Intégration (proxy) entre API Gateway et Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.precheck_lambda.invoke_arn
  payload_format_version = "2.0"
  integration_method     = "POST"
}

# ------------------------------------------------------------------------------
# AUTHORIZER JWT POUR KEYCLOAK
# ------------------------------------------------------------------------------
resource "aws_apigatewayv2_authorizer" "keycloak_jwt" {
  api_id           = aws_apigatewayv2_api.http_api.id
  authorizer_type  = "JWT"
  name             = "keycloak-jwt-authorizer"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = var.keycloak_issuer_url   # Ex: "https://keycloak.mondomaine.com/realms/mon-realm"
    audience = [var.keycloak_audience]   # Ex: ["mon-api-client"]
  }
}

# ------------------------------------------------------------------------------
# ROUTES API GATEWAY (Groupées proprement)
# ------------------------------------------------------------------------------

# Route POST /precheck avec l'authorizer Keycloak attaché
resource "aws_apigatewayv2_route" "precheck_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "POST /upload/check-chunks"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.keycloak_jwt.id
}

# Route OPTIONS /precheck SANS authorizer (Pour la pré-vérification CORS du navigateur)


# ------------------------------------------------------------------------------
# STAGE AVEC RATE LIMITING (THROTTLING)
# ------------------------------------------------------------------------------
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 20   # Rafale max (burst)
    throttling_rate_limit  = 10   # Requêtes par seconde en continu
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# Groupe de logs pour l'API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.http_api.name}"
  retention_in_days = 7
}

# Permission pour qu'API Gateway puisse invoquer la Lambda
resource "aws_lambda_permission" "apigw_allow_invoke_precheck" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.precheck_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
