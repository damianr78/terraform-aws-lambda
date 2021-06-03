locals {
  bucket_path        = "builds/${var.repo_name}/${module.lambda-label.artifact_id}/${module.lambda-label.artifact_version}"
  vpc_policy         = length(var.subnet_ids) > 0 ? ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"] : []
  assume_role_policy = var.attach_assume_role_policy ? ["arn:aws:iam::${data.aws_caller_identity.current_caller.account_id}:policy/iam_p_assume_role"] : []
  rule_name          = "${local.function_name}-${module.lambda-label.environment_upper}-WARMUP"
  targets_dlq        = var.dead_letter_queue_name != "" ? [var.dead_letter_queue_name] : []
  warm_up_enabled    = contains(var.warm_up_available_environments, module.lambda-label.environment_upper)
  function_name      = var.function_name != "" ? var.function_name : module.lambda-label.function_name
}

resource "aws_lambda_permission" "allow_cloudwatch_warm_up" {
  count = local.warm_up_enabled ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatchWarmUp"
  action        = "lambda:InvokeFunction"
  function_name = local.function_name
  qualifier     = module.lambda-label.environment_upper
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:rule/${local.rule_name}"
  depends_on = [
    aws_cloudwatch_event_rule.lambda_cloudwatch_rule
  ]
}

resource "aws_lambda_permission" "resource_based_policy" {
  count = var.enable_rbp ? 1 : 0

  statement_id  = var.rbp_statement_id
  action        = var.rbp_action
  function_name = local.function_name
  qualifier     = module.lambda-label.environment_upper
  principal     = var.rbp_principal
}

module "lambda-label" {
  source               = "git@github.com:Bancar/terraform-label.git//lambda?ref=tags/2.7"
  environment          = var.environment
  artifact_id          = var.artifact_id
  artifact_version     = var.artifact_version
  prefix_function_name = var.prefix_function_name
  tags                 = var.tags
}

## S3
data "aws_s3_bucket_object" "hash" {
  bucket = var.product_bucket
  key    = "${local.bucket_path}/${module.lambda-label.artifact_id}.hash"
}

## Permissions
module "lambda_role" {
  source             = "git@github.com:Bancar/terraform-aws-iam-roles.git?ref=tags/1.9"
  environment        = module.lambda-label.environment_lower
  account_id         = data.aws_caller_identity.current_caller.account_id
  assume_role_index  = "LAMBDA"
  role_name          = "${local.function_name}Role-${module.lambda-label.environment_lower}"
  custom_policies    = var.lambda_policy_path != "" ? [var.lambda_policy_path] : []
  policy_custom_vars = var.policy_lambda_vars
  tags               = var.tags

  policies_arn = concat(
    local.vpc_policy,
    local.assume_role_policy,
    [coalesce(var.base_policy_arn, "arn:aws:iam::${data.aws_caller_identity.current_caller.account_id}:policy/iam_p_lambda_configs")]
  )
}

resource "time_offset" "alias_version_update" {
  triggers = {
    # Save the time each switch of Lambda Version
    lambda_version = aws_lambda_function.lambda.version
  }

  offset_hours = -3
}

## Lambda
resource "aws_lambda_alias" "alias" {
  name             = module.lambda-label.environment_upper
  function_name    = aws_lambda_function.lambda.arn
  function_version = aws_lambda_function.lambda.version
  description      = "${module.lambda-label.environment_upper} VERSION ${module.lambda-label.artifact_version} - ${formatdate("DD-MM-YYYY hh:mm:ss", time_offset.alias_version_update.rfc3339)}"

  routing_config {
    additional_version_weights = var.additional_version_weights
  }
}

resource "aws_lambda_function" "lambda" {
  function_name                  = local.function_name
  description                    = var.function_description
  s3_bucket                      = var.product_bucket
  s3_key                         = "${local.bucket_path}/${module.lambda-label.artifact_id}.zip"
  role                           = module.lambda_role.role_arn[0]
  runtime                        = var.runtime
  handler                        = var.function_handler
  timeout                        = var.timeout
  memory_size                    = var.memory_size
  publish                        = true
  reserved_concurrent_executions = var.reserved_concurrent_executions
  source_code_hash               = replace(data.aws_s3_bucket_object.hash.body, "/\n$/", "")
  tags                           = module.lambda-label.tags
  layers                         = var.layers

  environment {
    variables = var.environment_variables
  }

  dynamic "dead_letter_config" {
    for_each = local.targets_dlq

    content {
      target_arn = "arn:aws:${var.dead_letter_queue_resource}:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_caller.account_id}:${var.dead_letter_queue_name}"
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0 ? [true] : []
    content {
      security_group_ids = var.security_group_ids
      subnet_ids         = var.subnet_ids
    }
  }

  dynamic "file_system_config" {
    for_each = length(var.efs_arn) > 0 ? [true] : []
    content {
      arn              = var.efs_arn
      local_mount_path = var.efs_local_mount_path
    }
  }

  depends_on = [
    module.lambda_role
  ]
}

resource "aws_lambda_permission" "allow_invocation_from_resource" {
  count = length(var.permissions_to_invoke)

  statement_id  = var.permissions_to_invoke[count.index].statement_id
  action        = "lambda:InvokeFunction"
  function_name = local.function_name
  principal     = "${var.permissions_to_invoke[count.index].principal_resource}.amazonaws.com"
  source_arn    = var.permissions_to_invoke[count.index].source_arn
  qualifier     = module.lambda-label.environment_upper

  depends_on = [
    aws_lambda_function.lambda
  ]
}

resource "aws_lambda_event_source_mapping" "dynamodb_trigger" {
  count = var.enable_dynamodb_trigger ? 1 : 0

  event_source_arn  = var.dynamodb_trigger_table_stream_arn
  function_name     = "${aws_lambda_function.lambda.arn}:${module.lambda-label.environment_upper}"
  starting_position = var.dynamodb_trigger_starting_position
  batch_size        = var.dynamodb_trigger_batch_size

  depends_on = [
    aws_lambda_alias.alias
  ]
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  count = var.enable_sqs_trigger ? 1 : 0

  batch_size                         = var.sqs_trigger_batch_size
  event_source_arn                   = var.sqs_trigger_queue_arn
  maximum_batching_window_in_seconds = var.sqs_max_window_in_seconds
  function_name                      = "${aws_lambda_function.lambda.arn}:${module.lambda-label.environment_upper}"

  depends_on = [
    aws_lambda_alias.alias
  ]
}

resource "aws_cloudwatch_event_rule" "lambda_cloudwatch_rule" {
  count               = local.warm_up_enabled ? 1 : 0
  name                = local.rule_name
  description         = "Warm up rule for lambda ${local.function_name}"
  schedule_expression = "rate(5 minutes)"
  tags                = merge(map("Name", local.rule_name), {})

  depends_on = [
    aws_lambda_function.lambda
  ]
}


resource "aws_cloudwatch_event_target" "lambda_cloudwatch_target" {
  count = local.warm_up_enabled ? 1 : 0
  arn   = "${aws_lambda_function.lambda.arn}:${module.lambda-label.environment_upper}"
  rule  = local.rule_name
  input = var.proxy ? "{\"body\": \"keepAlive\"}" : "{\"keepAlive\": true}"
  depends_on = [
    aws_lambda_function.lambda,
    aws_cloudwatch_event_rule.lambda_cloudwatch_rule
  ]
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  count = var.rule_arn == "" ? 0 : 1

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = local.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.rule_arn
  qualifier     = module.lambda-label.environment_upper

  depends_on = [
    aws_lambda_function.lambda
  ]
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  count = var.enable_s3_trigger ? 1 : 0

  bucket = var.s3_trigger_bucket

  dynamic "lambda_function" {
    for_each = aws_lambda_function.lambda.function_name
    content {
      id                  = aws_lambda_function.lambda.function_name
      lambda_function_arn = "${aws_lambda_function.lambda.arn}:${module.lambda-label.environment_upper}"
      events              = var.s3_trigger_events
      filter_prefix       = var.s3_trigger_key_prefix
      filter_suffix       = var.s3_trigger_key_suffix
    }
  }
  depends_on = [
    aws_lambda_permission.allow_bucket
  ]
}

resource "aws_lambda_permission" "allow_bucket" {
  count = var.enable_s3_trigger ? 1 : 0

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_trigger_bucket_arn
  qualifier     = module.lambda-label.environment_upper
}
