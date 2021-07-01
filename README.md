Terraform module to provision a Lambda function.

## Requirements

This module requires [AWS Provider](https://github.com/terraform-providers/terraform-provider-aws) `>= 1.17.0`

---

## Example Creating Lambda With VPC:

```hcl
module "lambda_odl_send_elasticsearch_event" {
  source = "git@github.com:Bancar/terraform-aws-lambda.git?ref=tags/3.1"

  artifact_id                     = var.artifact_id
  artifact_version                = var.artifact_version
  function_description            = var.function_description
  lambda_policy_path              = "${path.module}/../policies/iam_p_lambda_odl_send_elasticsearch_event.tpl"
  environment                     = var.environment
  product_bucket                  = var.product_bucket_lambda
  repo_name                       = var.repo_name_lambda
  runtime                         = "python3.7"
  function_handler                = "odl_send_elasticsearch_event.lambda_handler"
  subnet_ids                      = data.terraform_remote_state.vpc.outputs.private_subnets
  security_group_ids              = [data.terraform_remote_state.vpc.outputs.aws_security_group_id]
  memory_size                     = 128
  timeout                         = 45

  environment_variables    = {
      LOG_LEVEL = "DEBUG"
  }
  tags = var.tags
}
```

## Example Creating Lambda With Layers:

```hcl

module "lambda_odl_datalake_ingest_landing" {
   source = "git@github.com:Bancar/terraform-aws-lambda.git?ref=tags/3.1"

   artifact_id                     = var.artifact_id
   artifact_version                = var.artifact_version
   function_description            = var.function_description
   lambda_policy_path              = "${path.module}/../policies/iam_p_lambda_odl_datalake_ingest_landing.tpl"
   environment                     = var.environment
   product_bucket                  = var.product_bucket_lambda
   repo_name                       = var.repo_name_lambda
   runtime                         = "python3.7"
   function_handler                = "odl_datalake_ingest_landing.lambda_handler"
   subnet_ids                      = data.terraform_remote_state.vpc.outputs.private_subnets
   memory_size                     = 10240
   timeout                         = 900
   layers                          = [data.terraform_remote_state.layers.outputs.layer_wrangler_2_1_arn]
   environment_variables    = {
      ENVIRONMENT           = var.environment,
   }
   tags = var.tags
 }
 

```

## Example Creating Lambda With S3 Trigger:

```hcl
module "lambda_odl_datalake_ingest_landing" {
   source = "git@github.com:Bancar/terraform-aws-lambda.git?ref=tags/3.1"

   artifact_id                     = var.artifact_id
   artifact_version                = var.artifact_version
   function_description            = var.function_description
   lambda_policy_path              = "${path.module}/../policies/iam_p_lambda_odl_datalake_ingest_landing.tpl"
   environment                     = var.environment
   product_bucket                  = var.product_bucket_lambda
   repo_name                       = var.repo_name_lambda
   runtime                         = "python3.7"
   function_handler                = "odl_datalake_ingest_landing.lambda_handler"
   subnet_ids                      = data.terraform_remote_state.vpc.outputs.private_subnets
   memory_size                     = 10240
   timeout                         = 900
   enable_s3_trigger               = true
   s3_trigger_bucket               = data.terraform_remote_state.s3_core.outputs.bucket_landing_id
   s3_trigger_events               = ["s3:ObjectCreated:*"]
   s3_trigger_bucket_arn           = data.terraform_remote_state.s3_core.outputs.bucket_landing_arn
   environment_variables    = {
      ENVIRONMENT           = var.environment
   }
   tags = var.tags
 }
```

## Example Creating Lambda With CloudWatch:

```hcl
module "exportDynamoDBSnapshotsToS3" {
  source = "git@github.com:Bancar/terraform-aws-lambda.git?ref=tags/3.1"

  artifact_id                     = var.artifact_id
  artifact_version                = var.artifact_version
  function_description            = var.function_description
  lambda_policy_path              = "${path.module}/../policies/iam_p_exportDynamoDBSnapshotsToS3.tpl"
  environment                     = var.environment
  product_bucket                  = var.product_bucket_lambda
  repo_name                       = var.repo_name_lambda
  subnet_ids                      = data.terraform_remote_state.vpc.outputs.private_subnets
  security_group_ids              = [data.terraform_remote_state.vpc.outputs.aws_security_group_id]
  runtime                         = "python3.8"
  function_handler                = "exportDynamoDBSnapshotsToS3.lambda_handler"
  warm_up_available_environments  = []
  rule_arn                        = "arn:aws:events:us-east-1:${var.current_account_id}:rule/exportDynamoDBSnapshotsToS3"
  tags = var.tags
}

module "rule_exportDynamoDBSnapshotsToS3" {
  source = "git@github.com:Bancar/terraform-aws-cloudwatch-rule.git?ref=tags/1.4"

  environment             = var.environment
  rule_name               = "exportDynamoDBSnapshotsToS3"
  rule_description        = "Rule to invoke Lambda for Export Dynamo to S3"
  available_environments  = [upper(var.environment)]
  schedule_expression     = "cron(0 2 * * ? *)"
  business_unit           = var.business_unit
  owner                   = var.owner
}

module "target_exportDynamoDBSnapshotsToS3" {
  source               = "git@github.com:Bancar/terraform-aws-cloudwatch-target.git?ref=tags/1.4"
  environment          = var.environment
  cloudwatch_rule      = "exportDynamoDBSnapshotsToS3"
  target_arn           = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current_caller.account_id}:function:ExportDynamoDBSnapshotsToS3"
}

output "rule_exportDynamoDBSnapshotsToS3_name" {
  value = module.rule_exportDynamoDBSnapshotsToS3.rule_name[0]
}

output "rule_exportDynamoDBSnapshotsToS3_arn" {
  value = module.rule_exportDynamoDBSnapshotsToS3.rule_arn[0]
}
```


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| artifact_id | The id of the artifact (zip file) to be deployed without the .zip extension | string | `n/a` | yes |
| artifact_version | Version of the lambdas artifact | string | `n/a` | yes |
| dead_letter_queue_name | Dead letter queue name including environment name | string | `""` | no |
| dead_letter_queue_resource | Dead letter queue resource. Only sqs and sns are allowed | string | `"sqs"` | no |
| dynamodb_trigger_starting_position | Starting position for dynamodb trigger | string | `"LATEST"` | no |
| dynamodb_trigger_batch_size | The largest number of records that Lambda will retrieve from your event source at the time of invocation | string | `"100"` | no |
| environment | Environment name to use on all resources created (API-Gateway, Lambdas, etc.) | string | `n/a` | yes |
| environment_variables |  | map | `default_variable` | no |
| function_description | Description of the lambda function | string | `n/a` | yes |
| function_handler | Lambda Function entrypoint in your code | string | `"com.bancar.services.MainHandler"` | no |
| memory_size | Amount of memory in MB your Lambda Function can use at runtime. Valid value between 128 MB to 10,240 MB (10 GB), in 64 MB increments. | string | `"512"` | no |
| runtime | Runtime language for lambda | string | `"java8"` | no |
| security_group_ids | List of security group ids when Lambda Function should run in the VPC.	 | list(string) | `[]` | no |
| subnet_ids | List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets.	 | list(string) | `[]` | no |
| timeout | The amount of time your Lambda Function has to run in seconds.| string | `"900"` | no |
| tags | A map of tags to add to IAM role resources | map(string) | {} | no |
| warm_up_available_environments | Environments where warm up will be created | list(string) | `["PROD", "STAGE"]` | no |
| prefix_function_name | Prefix for function name, e.g. 'prefix-create-credit-transaction-aws-lambda' | string | `""` | no |
| enable_s3_trigger | Boolean to enable s3 trigger | boolean | `false` | no |
| s3_trigger_bucket | Bucket name that triggers lambda | string | `""` | no |
| s3_trigger_bucket_arn | ARN of the bucket that triggers lambda | string | `""` | no |
| s3_trigger_events | List of events that trigger lambda | list(string) | `[]` | no |
| s3_trigger_key_prefix | S3 key prefix | string | `""` | no |
| s3_trigger_key_suffix | S3 key suffix | string | `""` | no |
| reserved_concurrent_executions | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1 | `-1` | no ||
| proxy | Boolean to differentiate between normal lambdas and proxy and send a different warm-up event | bool | `false` | no |
| layers | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function | list(string) | `null` | no |
| sqs_max_window_in_seconds | The maximum amount of time to gather records before invoking the function | integer | `0` | no |
| product_bucket | S3 Bucket containing the lambda zip files | string |  | yes |
| repo_name | Name of repository who contains JAVA code of lambda | string |  | yes |
| lambda_policy_path | Policy's tpl path for the lambda | string | `""` | no |
| dynamodb_trigger_table_stream_arn | Table stream arn if enable_dynamodb_trigger is true | string | `""` | no |
| enable_dynamodb_trigger | Enable dynamodb trigger for lambda | bool | `true` | no |
| permissions_to_invoke | List of objects describing permisions to invoke lambda (for principal resource: only sns, apigateway, s3 or cloudwatch are allowed) source_arn is the arn of the resource invoking the lambda | list(object({ statement_id : string, principal_resource : string, source_arn : string })) | `[]` | no |
| function_name | Lambda name. If empty, module uses lambda-label function name | string | `""` | no |
| base_policy_arn | Base policy ARN to allow lambda to access logs and configs table | string | `""` | no |
| rule_arn | arn of rule | string | `""` | no |
| policy_lambda_vars | Optional Custom vars map for a policy | map(string) | `{}` | no |
| attach_assume_role_policy | Boolean to indicate if the iam_p_assume_role shoud be attached to the role | Bool | `false` | no |
| enable_sqs_trigger | Enable sqs trigger for lambda | Bool | `false` | no |
| sqs_trigger_queue_arn | SQS arn if enable_sqs_trigger is true | string | `""` | no |
| sqs_trigger_batch_size | The largest number of records that Lambda will retrieve from your event source at the time of invocation. | number | `1` | no |
| efs_arn | The Amazon Resource Name (ARN) of the Amazon EFS Access Point that provides access to the file system.| string | `""` | no |
| efs_local_mount_path | The path where the function can access the file system, starting with /mnt/.| string | `""` | no |
| additional_version_weights | Value to distribute the usability percentage (ej: 'version'=percentage '10'=0.5) | map(number)	 | `{}` | no |
| enable_rbp | Creates a custom resource based policy for lambda. | bool | `false` | no |
| rbp_statement_id | Statement id for the resource based policy. | string | `cross-account-invocation` | no |
| rbp_action | Action for the resource based policy. | string | `lambda:InvokeFunction` | no |
| rbp_principal | The principal who is getting this permission. | string | `events.amazonaws.com` | no |
| rbp_source_arn | The principal's ARN. | string | `""` | no |


## Outputs

| Name | Description |
|------|-------------|
| arn | The ARN of the Lambda Function |
| function_name | The name of the Lambda Function |
| alias_arn | The ARN of the Lambda Function Alias |
| alias_invoke_arn | The ARN to be used for invoking Lambda Function from API Gateway |
| invoke_arn | The Invoke ARN of the Lambda Function |
| alias_name | The name of the Lambda Function Alias |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
