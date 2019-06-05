variable "artifacts_bucket" {
  description = "S3 Bucket containing the lambda zip files"
}

variable "artifact_name" {
  description = "The name of the artifact (zip file) to be deployed without the .zip extension"
}

variable "stage" {
  description = "Stage name to use on all resources created (API-Gateway, Lambdas, etc.)"
}

variable "function_name" {
  description = "Name of the lambda function"
}

variable "function_description" {
  description = "Description of the lambda function"
}

variable "artifact_key_prefix" {
  description = "Prefix corresponding to the folder for the artifact in s3"
}

variable "lambda_policy_json" {
  description = "Policy's json for the lambda"
}

variable "function_handler" {
  description = "Handler for lambda function"
  default     = "com.bancar.services.MainHandler"
}

variable "artifact_version" {
  description = "Version of the lambdas artifact"
  default = "SNAPSHOT"
}

variable "environment_variables" {
  type = "map"
  default = {
    "default" = "default_variable"
  }
}

variable "security_group_ids" {
  type = "list"
  description = "Security groups ids for VPC"
  default = []
}

variable "subnet_ids" {
  type = "list"
  description = "Subnet ids for VPC"
  default = []
}

variable "dynamodb_trigger_table_name" {
  description = "Table name if the lambda is a dynamodb trigger"
  default = ""
}

variable "dynamodb_trigger_starting_position" {
  description = "Starting position for dynamodb trigger"
  default = "LATEST"
}

variable "permission_statement_id" {
  description = "Statement id for lambda execution permission"
  default = ""
}

variable "permission_resource" {
  description = "Resource for permission statement (only sns, apigateway, s3 or cloudwatch are allowed)"
  default = ""
}

variable "permission_source_arn" {
  description = "Source ARN for permission"
  default = ""
}

variable "timeout" {
  description = "Lambda timeout time in seconds"
  default = "900"
}

variable "memory_size" {
  description = "Lambda's size"
  default = "512"
}

variable "runtime" {
  description = "Runtime language for lambda"
  default = "java8"
}

variable "dead_letter_queue_name" {
  description = "Dead letter queue name without environment"
  default = ""
}

variable "dead_letter_queue_resource" {
  description = "Dead letter queue resource. Only sqs and sns are allowed"
  default = "sqs"
}