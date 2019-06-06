output "arn" {
  value = "${local.arn}"
}

output "function_name" {
  value = "${module.lambda-label.function_name}"
}