## General
module "lambda-label" {
  source           = "git@github.com:Bancar/terraform-label.git?ref=tags/1.1//lambda"
  environment      = "${var.environment}"
  artifact_id      = "${var.artifact_id}"
  artifact_version = "${var.artifact_version}"
}
data "aws_region" "current_region" {}

data "aws_caller_identity" "current_caller" {}

## S3
data "aws_s3_bucket" "artifacts" {
  bucket = "${var.artifacts_bucket}"
}

data "aws_s3_bucket_object" "hash" {
  bucket = "${var.artifacts_bucket}"
  key    = "${var.artifact_key_prefix}/${module.lambda-label.artifact_id}/${module.lambda-label.artifact_version}/${module.lambda-label.artifact_id}.hash"
}

## Permissions
data "aws_iam_policy" "base_policy" {
  arn = "arn:aws:iam::${data.aws_caller_identity.current_caller.account_id}:policy/Lambda_${module.lambda-label.environment_lower}Configs_Policy"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${module.lambda-label.function_name}Role-${module.lambda-label.environment_lower}"

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

  count = "${var.lambda_policy_json != "" ? 1 : 0}"
  name = "${module.lambda-label.function_name}Policy-${module.lambda-label.environment_lower}"

  policy = "${var.lambda_policy_json}"
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  count = "${var.lambda_policy_json != "" ? 1 : 0}"
  role      = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_role_policy_attachment" "base_policy_attach" {
  role      = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${data.aws_iam_policy.base_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "vpc_policy_attach" {
  count     = "${length(var.subnet_ids) > 0 ? 1 : 0}"
  role      = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

## Lambda
resource "aws_lambda_alias" "alias" {
  name             = "${module.lambda-label.environment_upper}"
  function_name    = "${local.arn}"
  function_version = "${local.version}"
  description = "${module.lambda-label.environment_upper} VERSION ${module.lambda-label.artifact_version} - ${trimspace(replace(timestamp(), "/[A-Z]/", " "))}"
  lifecycle {
    ignore_changes = ["description"]
  }
}

resource "aws_lambda_function" "lambda" {
  count = "${var.dead_letter_queue_name == "" ? 1 : 0}"
  function_name = "${module.lambda-label.function_name}"
  description   = "${var.function_description}"
  s3_bucket     = "${data.aws_s3_bucket.artifacts.id}"
  s3_key        = "${var.artifact_key_prefix}/${module.lambda-label.artifact_id}/${module.lambda-label.artifact_version}/${module.lambda-label.artifact_id}.zip"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  runtime       = "${var.runtime}"
  handler       = "${var.function_handler}"
  timeout       = "${var.timeout}"
  memory_size   = "${var.memory_size}"
  publish       = true
  source_code_hash = "${replace(data.aws_s3_bucket_object.hash.body, "/\n$/", "")}"
  vpc_config {
    security_group_ids = "${var.security_group_ids}"
    subnet_ids = "${var.subnet_ids}"
  }
  environment = {
    variables = "${var.environment_variables}"
  }
}

resource "aws_lambda_function" "lambda_with_dlq" {
  count             = "${var.dead_letter_queue_name != "" ? 1 : 0}"
  function_name     = "${module.lambda-label.function_name}"
  description       = "${var.function_description}"
  s3_bucket         = "${data.aws_s3_bucket.artifacts.id}"
  s3_key            = "${var.artifact_key_prefix}/${module.lambda-label.artifact_id}/${module.lambda-label.artifact_version}/${module.lambda-label.artifact_id}.zip"
  role              = "${aws_iam_role.iam_for_lambda.arn}"
  runtime           = "${var.runtime}"
  handler           = "${var.function_handler}"
  timeout           = "${var.timeout}"
  memory_size       = "${var.memory_size}"
  publish           = true
  source_code_hash  = "${replace(data.aws_s3_bucket_object.hash.body, "/\n$/", "")}"
  vpc_config {
    security_group_ids = "${var.security_group_ids}"
    subnet_ids         = "${var.subnet_ids}"
  }
  environment = {
    variables = "${var.environment_variables}"
  }
  dead_letter_config {
    target_arn = "arn:aws:${var.dead_letter_queue_resource}:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:${var.dead_letter_queue_name}-${module.lambda-label.environment_upper}"
  }
}

resource "aws_lambda_permission" "allow_invocation_from_resource" {
  count = "${var.permission_statement_id != "" ? 1 : 0}"
  statement_id  = "${var.permission_statement_id}"
  action        = "lambda:InvokeFunction"
  function_name = "${module.lambda-label.function_name}"
  principal     = "${var.permission_resource}.amazonaws.com"
  source_arn    = "${var.permission_source_arn}"
  qualifier     = "${module.lambda-label.environment_upper}"
}

resource "aws_lambda_event_source_mapping" "dynamodb_trigger" {
  count = "${var.dynamodb_trigger_table_name != "" ? 1 : 0}"
  event_source_arn  = "${data.aws_dynamodb_table.dynamodb_table.stream_arn}"
  function_name     = "${local.arn}:${module.lambda-label.environment_upper}"
  starting_position = "${var.dynamodb_trigger_starting_position}"
  depends_on = [
    "aws_lambda_alias.alias"
  ]
}

data "aws_dynamodb_table" "dynamodb_table" {
  count = "${var.dynamodb_trigger_table_name != "" ? 1 : 0}"
  name = "${module.lambda-label.environment_lower}${title(var.dynamodb_trigger_table_name)}"
}

locals {
  arn           = "${element(concat(aws_lambda_function.lambda.*.arn, aws_lambda_function.lambda_with_dlq.*.arn), 0)}"
  version       = "${element(concat(aws_lambda_function.lambda.*.version, aws_lambda_function.lambda_with_dlq.*.version), 0)}"
}
