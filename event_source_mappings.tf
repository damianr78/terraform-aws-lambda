
locals {
  dynamodb_event_sources = [for k, v in var.event_source_mappings : lookup(v, "event_source_arn", null)
  if length(regexall(".*:dynamodb:.*", lookup(v, "event_source_arn", null))) > 0]kinesis_event_sources  =
  [for k, v in var.event_source_mappings : lookup(v, "event_source_arn", null) if length(regexall(".*:kinesis:.*",
  lookup(v, "event_source_arn", null))) > 0]
}

resource "aws_lambda_event_source_mapping" "event_source" {
  for_each = var.event_source_mappings

  batch_size                         = lookup(each.value, "batch_size", null)
  bisect_batch_on_function_error     = lookup(each.value, "bisect_batch_on_function_error", null)
  enabled                            = lookup(each.value, "enabled", null)
  event_source_arn                   = lookup(each.value, "event_source_arn", null)
  function_name                      = lookup(each.value, "function_name", var.function_name)
  maximum_batching_window_in_seconds = lookup(each.value, "maximum_batching_window_in_seconds", null)
  maximum_retry_attempts             = lookup(each.value, "maximum_retry_attempts", null)
  maximum_record_age_in_seconds      = lookup(each.value, "maximum_record_age_in_seconds", null)
  parallelization_factor             = lookup(each.value, "parallelization_factor", null)
  starting_position                  = lookup(each.value, "starting_position", length(regexall(".*:sqs:.*", lookup(each.value, "event_source_arn", null))) > 0 ? null : "TRIM_HORIZON")
  starting_position_timestamp        = lookup(each.value, "starting_position_timestamp", null)
}