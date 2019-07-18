module "warm_up_target" {
  source                  = "git@github.com:Bancar/terraform-aws-cloudwatch-target.git?ref=1.1"
  cloudwatch_rule         = local.rule_name
  lambda_arn              = local.arn
  input                   = "{\"keepAlive\": true}"
  environment             = var.environment
  available_environments  = var.warm_up_available_environments
}

module "warm_up_rule"{
  source                  = "git@github.com:Bancar/terraform-aws-cloudwatch-rule.git?ref=1.1"
  rule_name               = local.rule_name
  rule_description        = "Warm up rule for lambda ${local.function_name}"
  schedule_expression     = "rate(5 minutes)"
  available_environments  = var.warm_up_available_environments
  environment             = var.environment
}

resource "aws_lambda_permission" "allow_cloudwatch_warm_up" {
  count         = "${contains(var.warm_up_available_environments, upper(var.environment)) ? 1 : 0}"
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${local.function_name}:${upper(var.environment)}"
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:rule/${local.rule_name}"
}

data "aws_region" "current_region" {
}

data "aws_caller_identity" "current_caller" {
}

## S3
data "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket
}

data "aws_s3_bucket_object" "hash" {
  bucket = var.artifacts_bucket
  key    = "${var.artifact_key_prefix}/${var.artifact_id}/${var.artifact_version}/${var.artifact_id}.hash"
}

## Permissions
data "aws_iam_policy" "base_policy" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current_caller.account_id}:policy/Lambda_${lower(var.environment)}Configs_Policy"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.function_name}Role-${lower(var.environment)}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy" "policy" {
  count = var.lambda_policy_json != "" ? 1 : 0
  name = "${var.function_name}Policy-${lower(var.environment)}"

  policy = var.lambda_policy_json
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  count = var.lambda_policy_json != "" ? 1 : 0
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy[0].arn
}

resource "aws_iam_role_policy_attachment" "base_policy_attach" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = data.aws_iam_policy.base_policy.arn
}

resource "aws_iam_role_policy_attachment" "vpc_policy_attach" {
  count = length(var.subnet_ids) > 0 ? 1 : 0
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

## Lambda
resource "aws_lambda_alias" "alias" {
  name = upper(var.environment)
  function_name = local.arn
  function_version = local.version
  description = "${upper(var.environment)} VERSION ${var.artifact_version} - ${trimspace(replace(timestamp(), "/[A-Z]/", " "))}"
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_lambda_function" "lambda" {
  count = var.dead_letter_queue_name == "" ? 1 : 0
  function_name = var.function_name
  description = var.function_description
  s3_bucket = data.aws_s3_bucket.artifacts.id
  s3_key = "${var.artifact_key_prefix}/${var.artifact_id}/${var.artifact_version}/${var.artifact_id}.zip"
  role = aws_iam_role.iam_for_lambda.arn
  runtime = var.runtime
  handler = var.function_handler
  timeout = var.timeout
  memory_size = var.memory_size
  publish = true
  source_code_hash = replace(data.aws_s3_bucket_object.hash.body, "/\n$/", "")
  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids = var.subnet_ids
  }
  environment {
    variables = var.environment_variables
  }
}

resource "aws_lambda_function" "lambda_with_dlq" {
  count = var.dead_letter_queue_name != "" ? 1 : 0
  function_name = var.function_name
  description = var.function_description
  s3_bucket = data.aws_s3_bucket.artifacts.id
  s3_key = "${var.artifact_key_prefix}/${var.artifact_id}/${var.artifact_version}/${var.artifact_id}.zip"
  role = aws_iam_role.iam_for_lambda.arn
  runtime = var.runtime
  handler = var.function_handler
  timeout = var.timeout
  memory_size = var.memory_size
  publish = true
  source_code_hash = replace(data.aws_s3_bucket_object.hash.body, "/\n$/", "")
  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids = var.subnet_ids
  }
  environment {
    variables = var.environment_variables
  }
  dead_letter_config {
    target_arn = "arn:aws:${var.dead_letter_queue_resource}:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:${var.dead_letter_queue_name}-${upper(var.environment)}"
  }
}

resource "aws_lambda_permission" "allow_invocation_from_resource" {
  count = var.permission_statement_id != "" ? 1 : 0
  statement_id = var.permission_statement_id
  action = "lambda:InvokeFunction"
  function_name = var.function_name
  principal = "${var.permission_resource}.amazonaws.com"
  source_arn = var.permission_source_arn
  qualifier = upper(var.environment)
}

resource "aws_lambda_event_source_mapping" "dynamodb_trigger" {
  count = var.dynamodb_trigger_table_name != "" ? 1 : 0
  event_source_arn = data.aws_dynamodb_table.dynamodb_table[0].stream_arn
  function_name = "${local.arn}:${upper(var.environment)}"
  starting_position = var.dynamodb_trigger_starting_position
  depends_on = [aws_lambda_alias.alias]
}

data "aws_dynamodb_table" "dynamodb_table" {
  count = var.dynamodb_trigger_table_name != "" ? 1 : 0
  name = "${lower(var.environment)}${title(var.dynamodb_trigger_table_name)}"
}

locals {
  arn = element(
    concat(
      aws_lambda_function.lambda.*.arn,
      aws_lambda_function.lambda_with_dlq.*.arn,
    ),
    0,
  )
  version = element(
    concat(
      aws_lambda_function.lambda.*.version,
      aws_lambda_function.lambda_with_dlq.*.version,
    ),
    0,
  )
  function_name = element(
    concat(
    aws_lambda_function.lambda.*.function_name,
    aws_lambda_function.lambda_with_dlq.*.function_name,
    ),
    0,
  )
  rule_name = "${local.function_name}-${upper(var.environment)}"
}

