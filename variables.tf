variable "product_bucket" {
  description = "S3 Bucket containing the lambda zip files"
}

variable "repo_name" {
  description = "Name of repository who contains JAVA code of lambda"
}

variable "artifact_id" {
  description = "The id of the artifact (zip file) to be deployed without the .zip extension"
}

variable "environment" {
  description = "Environment name to use on all resources created (API-Gateway, Lambdas, etc.)"
}

variable "function_description" {
  description = "Description of the lambda function"
}

variable "lambda_policy_path" {
  description = "Policy's tpl path for the lambda"
  default     = ""
}

variable "function_handler" {
  description = "Handler for lambda function"
  default     = "com.bancar.services.MainHandler"
}

variable "artifact_version" {
  type        = string
  description = "Version of the lambdas artifact"
}

variable "prefix_function_name" {
  type        = string
  description = "Prefix for function name, e.g. 'prefix-create-credit-transaction-aws-lambda'"
  default     = ""
}

variable "environment_variables" {
  type = map(string)
  default = {
    "default" = "default_variable"
  }
}

# variable "security_group_ids" {
#   type        = list(string)
#   description = "Security groups ids for VPC"
#   default     = []
# }

# variable "subnet_ids" {
#   type        = list(string)
#   description = "Subnet ids for VPC"
#   default     = []
# }

variable "subnet_ids" {
  description = "List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group ids when Lambda Function should run in the VPC."
  type        = list(string)
  default     = []
}

variable "dynamodb_trigger_table_stream_arn" {
  description = "Table stream arn if enable_dynamodb_trigger is true"
  default     = ""
}

variable "enable_dynamodb_trigger" {
  description = "Enable dynamodb trigger for lambda"
  default     = false
}

variable "dynamodb_trigger_starting_position" {
  description = "Starting position for dynamodb trigger"
  default     = "LATEST"
}

variable "dynamodb_trigger_batch_size" {
  description = "The largest number of records that Lambda will retrieve from your event source at the time of invocation"
  default     = "100"
}

variable "permissions_to_invoke" {
  description = "List of objects describing permisions to invoke lambda (for principal resource: only sns, apigateway, s3 or cloudwatch are allowed) source_arn is the arn of the resource invoking the lambda"
  type        = list(object({ statement_id : string, principal_resource : string, source_arn : string }))
  default     = []
}

variable "timeout" {
  description = "Lambda timeout time in seconds"
  default     = "900"
}

variable "memory_size" {
  description = "Lambda's size"
  default     = "512"
}

variable "runtime" {
  description = "Runtime language for lambda"
  default     = "java8"
}

variable "dead_letter_queue_name" {
  description = "Dead letter queue name including environment name"
  default     = ""
}

variable "function_name" {
  description = "Lambda name. If empty, module uses lambda-label function name"
  default     = ""
}

variable "dead_letter_queue_resource" {
  description = "Dead letter queue resource. Only sqs and sns are allowed"
  default     = "sqs"
}

variable "use_configs_table" {
  description = "Flag to enable use to configs table"
  default     = true
}

variable "base_policy_arn" {
  description = "Base policy ARN to allow lambda to access logs and configs table"
  default     = ""
}

variable "rule_arn" {
  description = "arn of rule"
  default     = ""
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
}

variable "policy_lambda_vars" {
  type        = map(string)
  default     = {}
  description = "Optional Custom vars map for a policy"
}

variable "warm_up_available_environments" {
  type        = list(string)
  description = "Environments where warm up will be created"
  default     = ["PROD", "STAGE"]
}

variable "enable_s3_trigger" {
  description = "Enable s3 trigger for lambda"
  default     = false
}

variable "s3_trigger_bucket" {
  description = "S3 Bucket that triggers lambda"
  type        = string
  default     = ""
}

variable "s3_trigger_bucket_arn" {
  description = "S3 Bucket ARN that triggers lambda"
  type        = string
  default     = ""
}

variable "enable_s3_trigger_2" {
  description = "Enable s3 trigger for lambda"
  default     = false
}

variable "s3_trigger_bucket_2" {
  description = "S3 Bucket that triggers lambda"
  type        = string
  default     = ""
}

variable "s3_trigger_bucket_arn_2" {
  description = "S3 Bucket ARN that triggers lambda"
  type        = string
  default     = ""
}

variable "s3_trigger_events" {
  description = "List of events that invoke lambda function"
  type        = list(string)
  default     = []
}

variable "s3_trigger_key_prefix" {
  description = "S3 key prefix"
  default     = ""
}

variable "s3_trigger_key_suffix" {
  description = "S3 key suffix"
  default     = ""
}

variable "proxy" {
  description = "Boolean to differentiate between normal lambdas and proxy and send a different warm-up event"
  default     = false
}

variable "attach_assume_role_policy" {
  description = "Boolean to indicate if the iam_p_assume_role shoud be attached to the role"
  default     = false
}

variable "enable_sqs_trigger" {
  description = "Enable sqs trigger for lambda"
  default     = false
}

variable "sqs_trigger_queue_arn" {
  description = "SQS arn if enable_sqs_trigger is true"
  default     = ""
}
variable "sqs_max_window_in_seconds" {
  description = "The maximum amount of time to gather records before invoking the function"
  default     = 0
}

variable "sqs_trigger_batch_size" {
  description = "The largest number of records that Lambda will retrieve from your event source at the time of invocation."
  default     = 1
}

variable "reserved_concurrent_executions" {
  description = "The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1"
  default     = -1
}

variable "layers" {
  default     = null
  description = "List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function"
  type        = list(string)
}

variable "efs_arn" {
  type        = string
  default     = ""
  description = "EFS ARN file system"
}

variable "efs_local_mount_path" {
  type        = string
  default     = ""
  description = "EFS path file system"
}

variable "additional_version_weights" {
  default     = {}
  description = "Value to distribute the usability percentage (ej: 'version'=percentage '10'=0.5)"
}

variable "enable_rbp" {
  description = "Creates a custom resource based policy for lambda."
  default     = false
}

variable "rbp_statement_id" {
  description = "Statement id for the resource based policy"
  default     = "cross-account-invocation"
}

variable "rbp_action" {
  description = "Action for the resource based policy"
  default     = "lambda:InvokeFunction"
}

variable "rbp_principal" {
  description = "The principal who is getting this permission"
  default     = "events.amazonaws.com"
}