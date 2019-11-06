output "arn" {
  value = local.arn
}

output "function_name" {
  value = module.lambda-label.function_name
}

output "invoke_arn" {
  value = local.invoke_arn
}

output "alias_invoke_arn" {
  value = aws_lambda_alias.alias.invoke_arn
}

output "alias_name" {
  description = "Used for API Gateway permission to allow lambda invocations"
  value       = "${module.lambda-label.function_name}:${aws_lambda_alias.alias.name}"
}