locals {
  bucket_path = "builds/${var.repo_name}/${module.lambda-label.artifact_id}/${module.lambda-label.artifact_version}"
  
  arn = concat(
      aws_lambda_function.lambda.*.arn,
      aws_lambda_function.lambda_with_dlq.*.arn,
    )[0]
  
  invoke_arn = concat(
      aws_lambda_function.lambda.*.invoke_arn,
      aws_lambda_function.lambda_with_dlq.*.invoke_arn,
    )[0]
  
  version = concat(
      aws_lambda_function.lambda.*.version,
      aws_lambda_function.lambda_with_dlq.*.version,
    )[0]

  vpc_policy = length(var.subnet_ids) > 0 ? ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"] : []
}

module "lambda-label" {
  source           = "git@github.com:Bancar/terraform-label.git//lambda?ref=tags/2.0"
  environment      = var.environment
  artifact_id      = var.artifact_id
  artifact_version = var.artifact_version
}

## S3
data "aws_s3_bucket_object" "hash" {
  bucket = var.product_bucket
  key    = "${local.bucket_path}/${module.lambda-label.artifact_id}.hash"
}
  
## Permissions
module "lambda_role" {
  source            = "git@github.com:Bancar/terraform-aws-iam-roles.git?ref=tags/1.7"

  environment       = var.environment
  account_id        = data.aws_caller_identity.current_caller.account_id

  assume_role_index = "LAMBDA"
  role_name         = "${module.lambda-label.function_name}Role-${module.lambda-label.environment_lower}"

  policies_arn = concat(
    local.vpc_policy,
    [aws_iam_policy.policy[0].arn, coalesce(var.base_policy_arn, "arn:aws:iam::${data.aws_caller_identity.current_caller.account_id}:policy/iam_p_lambda_configs")]
  )
}

resource "aws_iam_policy" "policy" {
  count   = var.lambda_policy_json != "" ? 1 : 0
  
  name    = "${module.lambda-label.function_name}Policy-${module.lambda-label.environment_lower}"
  policy  = var.lambda_policy_json
}

## Lambda
resource "aws_lambda_alias" "alias" {
  name              = module.lambda-label.environment_upper
  function_name     = local.arn
  function_version  = local.version
  description       = "${module.lambda-label.environment_upper} VERSION ${module.lambda-label.artifact_version} - ${trimspace(replace(timestamp(), "/[A-Z]/", " "))}"
  
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_lambda_function" "lambda" {
  count             = var.dead_letter_queue_name == "" ? 1 : 0
  function_name     = module.lambda-label.function_name
  description       = var.function_description
  s3_bucket         = var.product_bucket
  s3_key            = "${local.bucket_path}/${module.lambda-label.artifact_id}.zip"
  role              = module.lambda_role.role_arn[0]
  runtime           = var.runtime
  handler           = var.function_handler
  timeout           = var.timeout
  memory_size       = var.memory_size
  publish           = true
  source_code_hash  = replace(data.aws_s3_bucket_object.hash.body, "/\n$/", "")
  
  vpc_config {
    security_group_ids  = var.security_group_ids
    subnet_ids          = var.subnet_ids
  }
  environment {
    variables = var.environment_variables
  }
}

resource "aws_lambda_function" "lambda_with_dlq" {
  count             = var.dead_letter_queue_name != "" ? 1 : 0
  function_name     = module.lambda-label.function_name
  description       = var.function_description
  s3_bucket         = var.product_bucket
  s3_key            = "${local.bucket_path}/${module.lambda-label.artifact_id}.zip"
  role              = module.lambda_role.role_arn[0]
  runtime           = var.runtime
  handler           = var.function_handler
  timeout           = var.timeout
  memory_size       = var.memory_size
  publish           = true
  source_code_hash  = replace(data.aws_s3_bucket_object.hash.body, "/\n$/", "")
  
  vpc_config {
    security_group_ids  = var.security_group_ids
    subnet_ids          = var.subnet_ids
  }
  environment {
    variables = var.environment_variables
  }
  dead_letter_config {
    target_arn = "arn:aws:${var.dead_letter_queue_resource}:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:${var.dead_letter_queue_name}"
  }
}

resource "aws_lambda_permission" "allow_invocation_from_resource" {
  count           = length(var.permissions_to_invoke)
  
  statement_id    = var.permissions_to_invoke[count.index].statement_id
  action          = "lambda:InvokeFunction"
  function_name   = module.lambda-label.function_name
  principal       = "${var.permissions_to_invoke[count.index].principal_resource}.amazonaws.com"
  source_arn      = var.permissions_to_invoke[count.index].source_arn
  qualifier       = module.lambda-label.environment_upper
}

resource "aws_lambda_event_source_mapping" "dynamodb_trigger" {
  count             = var.dynamodb_trigger_table_name != "" ? 1 : 0
  
  event_source_arn  = data.aws_dynamodb_table.dynamodb_table[0].stream_arn
  function_name     = "${local.arn}:${module.lambda-label.environment_upper}"
  starting_position = var.dynamodb_trigger_starting_position
  
  depends_on        = [
    aws_lambda_alias.alias
  ]
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  count         = var.rule_arn == "" ? 0 : 1
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-label.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.rule_arn
  qualifier       = module.lambda-label.environment_upper
}

data "aws_dynamodb_table" "dynamodb_table" {
  count = var.dynamodb_trigger_table_name != "" ? 1 : 0
  
  name  = "${module.lambda-label.environment_lower}${title(var.dynamodb_trigger_table_name)}"
}
