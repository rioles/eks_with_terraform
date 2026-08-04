output "lambda_security_group_id" {
  description = "ID du Security Group de la Lambda"
  value       = aws_security_group.lambda_precheck_security_group.id
}

output "lambda_function_name" {
  description = "Nom de la fonction Lambda"
  value       = aws_lambda_function.precheck_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN de la fonction Lambda"
  value       = aws_lambda_function.precheck_lambda.arn
}

output "api_gateway_url" {
  description = "URL publique de l'API Gateway"
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}


