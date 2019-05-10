Terraform module to provision a Lambda function.

## Requirements

This module requires [AWS Provider](https://github.com/terraform-providers/terraform-provider-aws) `>= 1.17.0`


---

## Usage

```hcl
module "dynamodb_table" {
  source               = "git@github.com:Bancar/terraform-aws-lambda.git?ref=tags/1.0"
  function_name        = "FunctionNameService"
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



## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|


## Outputs

| Name | Description |
|------|-------------|
