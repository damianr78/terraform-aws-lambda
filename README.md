Terraform module to provision a Lambda function.

## Requirements

This module requires [AWS Provider](https://github.com/terraform-providers/terraform-provider-aws) `>= 1.17.0`


---

## Usage

```hcl
module "Lambda" {
  source               = "git@github.com:Bancar/terraform-aws-lambda.git?ref=tags/2.16"
  artifact_name        = "artifact-name-aws-lambda"
  artifact_version     = "1.0.0-SNAPSHOT"
  function_description = "Description of function name"

  environment_variables = {
    "AUTHORIZATION_SNS_ARN" = "${var.AuthorizationTopic_arn}"
  }

  lambda_policy_json = "${data.aws_iam_policy_document.create_credit_authorization_policy_document.json}"

  stage               = "${var.environment}"
  artifacts_bucket    = "${var.artifacts_bucket}"
  artifact_key_prefix = "${var.artifacts_key_prefix}"
}
```


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| artifact\_id | The id of the artifact (zip file) to be deployed without the .zip extension | string | n/a | yes |
| artifact\_key\_prefix | Prefix corresponding to the folder for the artifact in s3 | string | n/a | yes |
| artifact\_version | Version of the lambdas artifact | string | `"SNAPSHOT"` | no |
| artifacts\_bucket | S3 Bucket containing the lambda zip files | string | n/a | yes |
| dead\_letter\_queue\_name | Dead letter queue name including environment name | string | `""` | no |
| dead\_letter\_queue\_resource | Dead letter queue resource. Only sqs and sns are allowed | string | `"sqs"` | no |
| dynamodb\_trigger\_starting\_position | Starting position for dynamodb trigger | string | `"LATEST"` | no |
| dynamodb\_trigger\_table\_name | Table name if the lambda is a dynamodb trigger | string | `""` | no |
| environment | Environment name to use on all resources created (API-Gateway, Lambdas, etc.) | string | n/a | yes |
| environment\_variables |  | map | `<map>` | no |
| function\_description | Description of the lambda function | string | n/a | yes |
| function\_handler | Handler for lambda function | string | `"com.bancar.services.MainHandler"` | no |
| lambda\_policy\_json | Policy's json for the lambda | string | n/a | yes |
| memory\_size | Lambda's size | string | `"512"` | no |
| permission\_resource | Resource for permission statement (only sns, apigateway, s3 or cloudwatch are allowed) | string | `""` | no |
| permission\_source\_arn | Source ARN for permission | string | `""` | no |
| permission\_statement\_id | Statement id for lambda execution permission | string | `""` | no |
| runtime | Runtime language for lambda | string | `"java8"` | no |
| security\_group\_ids | Security groups ids for VPC | list | `<list>` | no |
| subnet\_ids | Subnet ids for VPC | list | `<list>` | no |
| timeout | Lambda timeout time in seconds | string | `"900"` | no |
| tags | A map of tags to add to IAM role resources | map(string) | {} | no |
| warm_up_available_environments | Environments where warm up will be created | list(string) | ["PROD", "STAGE"] | no
| prefix_function_name | Prefix for function name, e.g. 'prefix-create-credit-transaction-aws-lambda' | string | `""` | no |
| owner | Owner to be used on all the resources as identifier | string | | yes
| business_unit | Business Unit to be used on all the resources as identifier | string | | yes
| enable_s3_trigger | Boolean to enable s3 trigger | boolean | false | no
| s3_trigger_bucket | Bucket name that triggers lambda | string | "" | no
| s3_trigger_bucket_arn | ARN of the bucket that triggers lambda | string | "" | no
| s3_trigger_events | List of events that trigger lambda | list | [] | no
| filter_prefix | Prefix of bucket key | string | "" | no
| filter_suffix | Suffix of bucket key | string | "" | no
| proxy | Boolean to differentiate between normal lambdas and proxy and send a different warm-up event | bool | false | no

## Outputs

| Name | Description |
|------|-------------|
| arn |  |
| function\_name |  |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
