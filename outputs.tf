output "arn" {
  value = aws_lambda_function.lambda.arn
}

output "function_name" {
  value = local.function_name
}

output "alias_arn" {
  value = aws_lambda_alias.alias.arn
}

output "alias_invoke_arn" {
  value = aws_lambda_alias.alias.invoke_arn
}

output "invoke_arn" {
  value = aws_lambda_function.lambda.invoke_arn
}

output "alias_name" {
  description = "Used for API Gateway permission to allow lambda invocations"
  value       = "${module.lambda-label.function_name}:${aws_lambda_alias.alias.name}"
}