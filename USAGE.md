# Usage
<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| time | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| artifact\_id | The id of the artifact (zip file) to be deployed without the .zip extension | `any` | n/a | yes |
| artifact\_version | Version of the lambdas artifact | `string` | n/a | yes |
| attach\_assume\_role\_policy | Boolean to indicate if the iam\_p\_assume\_role shoud be attached to the role | `bool` | `false` | no |
| base\_policy\_arn | Base policy ARN to allow lambda to access logs and configs table | `string` | `""` | no |
| dead\_letter\_queue\_name | Dead letter queue name including environment name | `string` | `""` | no |
| dead\_letter\_queue\_resource | Dead letter queue resource. Only sqs and sns are allowed | `string` | `"sqs"` | no |
| dynamodb\_trigger\_batch\_size | The largest number of records that Lambda will retrieve from your event source at the time of invocation | `string` | `"100"` | no |
| dynamodb\_trigger\_starting\_position | Starting position for dynamodb trigger | `string` | `"LATEST"` | no |
| dynamodb\_trigger\_table\_stream\_arn | Table stream arn if enable\_dynamodb\_trigger is true | `string` | `""` | no |
| enable\_dynamodb\_trigger | Enable dynamodb trigger for lambda | `bool` | `false` | no |
| enable\_s3\_trigger | Enable s3 trigger for lambda | `bool` | `false` | no |
| enable\_sqs\_trigger | Enable sqs trigger for lambda | `bool` | `false` | no |
| environment | Environment name to use on all resources created (API-Gateway, Lambdas, etc.) | `any` | n/a | yes |
| environment\_variables | n/a | `map(string)` | <pre>{<br>  "default": "default_variable"<br>}</pre> | no |
| function\_description | Description of the lambda function | `any` | n/a | yes |
| function\_handler | Handler for lambda function | `string` | `"com.bancar.services.MainHandler"` | no |
| function\_name | Lambda name. If empty, module uses lambda-label function name | `string` | `""` | no |
| lambda\_policy\_path | Policy's tpl path for the lambda | `string` | `""` | no |
| layers | List of Lambda Layer Version ARNs (maximum of 5) to attach to your Lambda Function | `list(string)` | `null` | no |
| memory\_size | Lambda's size | `string` | `"512"` | no |
| permissions\_to\_invoke | List of objects describing permisions to invoke lambda (for principal resource: only sns, apigateway, s3 or cloudwatch are allowed) source\_arn is the arn of the resource invoking the lambda | `list(object({ statement_id : string, principal_resource : string, source_arn : string }))` | `[]` | no |
| policy\_lambda\_vars | Optional Custom vars map for a policy | `map(string)` | `{}` | no |
| prefix\_function\_name | Prefix for function name, e.g. 'prefix-create-credit-transaction-aws-lambda' | `string` | `""` | no |
| product\_bucket | S3 Bucket containing the lambda zip files | `any` | n/a | yes |
| proxy | Boolean to differentiate between normal lambdas and proxy and send a different warm-up event | `bool` | `false` | no |
| repo\_name | Name of repository who contains JAVA code of lambda | `any` | n/a | yes |
| reserved\_concurrent\_executions | The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1 | `number` | `-1` | no |
| rule\_arn | arn of rule | `string` | `""` | no |
| runtime | Runtime language for lambda | `string` | `"java8"` | no |
| s3\_trigger\_bucket | S3 Bucket that triggers lambda | `string` | `""` | no |
| s3\_trigger\_bucket\_arn | S3 Bucket ARN that triggers lambda | `string` | `""` | no |
| s3\_trigger\_events | List of events that invoke lambda function | `list(string)` | `[]` | no |
| s3\_trigger\_key\_prefix | S3 key prefix | `string` | `""` | no |
| s3\_trigger\_key\_suffix | S3 key suffix | `string` | `""` | no |
| security\_group\_ids | List of security group ids when Lambda Function should run in the VPC. | `list(string)` | `[]` | no |
| sqs\_trigger\_batch\_size | The largest number of records that Lambda will retrieve from your event source at the time of invocation. | `number` | `1` | no |
| sqs\_trigger\_queue\_arn | SQS arn if enable\_sqs\_trigger is true | `string` | `""` | no |
| subnet\_ids | List of subnet ids when Lambda Function should run in the VPC. Usually private or intra subnets. | `list(string)` | `[]` | no |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | `map(string)` | `{}` | no |
| timeout | Lambda timeout time in seconds | `string` | `"900"` | no |
| use\_configs\_table | Flag to enable use to configs table | `bool` | `true` | no |
| warm\_up\_available\_environments | Environments where warm up will be created | `list(string)` | <pre>[<br>  "PROD",<br>  "STAGE"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| alias\_arn | n/a |
| alias\_invoke\_arn | n/a |
| alias\_name | Used for API Gateway permission to allow lambda invocations |
| arn | n/a |
| function\_name | n/a |
| invoke\_arn | n/a |

<!--- END_TF_DOCS --->
