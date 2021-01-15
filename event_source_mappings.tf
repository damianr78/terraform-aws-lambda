
resource "aws_lambda_event_source_mapping" "event_source" {
  for_each = var.table_name_triggers


  batch_size                         = 1
  bisect_batch_on_function_error     = false
  enabled                            = true
  event_source_arn                   = lookup(each.value, "event_source_arn", null)
  function_name                      = lookup(each.value, "function_name", var.dynamodb_backup_function_name)
//  maximum_batching_window_in_seconds = lookup(each.value, "maximum_batching_window_in_seconds", null)
//  maximum_retry_attempts             = lookup(each.value, "maximum_retry_attempts", null)
//  maximum_record_age_in_seconds      = lookup(each.value, "maximum_record_age_in_seconds", null)
//  parallelization_factor             = lookup(each.value, "parallelization_factor", null)
//  starting_position                  = lookup(each.value, "starting_position", length(regexall(".*:sqs:.*", lookup(each.value, "event_source_arn", null))) > 0 ? null : "TRIM_HORIZON")
//  starting_position_timestamp        = lookup(each.value, "starting_position_timestamp", null)
}