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
}

variable "function_handler" {
  description = "Handler for lambda function"
  default     = "com.bancar.services.MainHandler"
}

variable "artifact_version" {
  type        = string
  description = "Version of the lambdas artifact"
}

variable "environment_variables" {
  type = map(string)
  default = {
    "default" = "default_variable"
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups ids for VPC"
  default     = []
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet ids for VPC"
  default     = []
}

variable "dynamodb_trigger_table_name" {
  description = "Table name if the lambda is a dynamodb trigger"
  default     = ""
}

variable "dynamodb_trigger_starting_position" {
  description = "Starting position for dynamodb trigger"
  default     = "LATEST"
}

variable "permissions_to_invoke" {
  description = "List of objects describing permisions to invoke lambda (for principal resource: only sns, apigateway, s3 or cloudwatch are allowed) source_arn is the arn of the resource invoking the lambda"
  type = list(object({statement_id: string, principal_resource: string, source_arn: string}))
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
