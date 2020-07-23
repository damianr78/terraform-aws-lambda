## 2.22
### Updated
- Required Security Group Ids and Subnet Ids

## 2.14
### Updated
- Refactor DLQ

## 2.13
### Updated
- Rollback of cloudwatch def
### Added
- S3 trigger

## 2.9
### Updated
- Tag all resources
### Added
- Warm up

## 2.8
### Added
- Add depens on to create resources

## 2.7
### Updated
- remove random id

## 2.6
### Updated
- Change to new structure bucket to save .zip and .hash

## 2.5
### Updated
- Load artifact version dynamically

## 2.4
### Added
- Add outputs for Alias invoke arn and name 

## 2.3
### Updated
- Use iam role module

## 2.2
### Updated 
- Update dlq config

## 2.1
### Added 
- New flag to use config table

## 2.0
### Updated
- Migration to terraform 0.12

## 1.4
### Updated
- Begin using terraform-lambda for naming-conventions
- Change variable stage to environment

## 1.3
### Added
- New resource is created instead of original lambda resource to add DLQ if dead_letter_queue_name variable is set

## 1.2
### Added
- DynamoDB trigger is created after updating iam policy to avoid permission denied

## 1.1
### Added
- VPC policy is attached automatically if VPC is set

## 1.0
### Added
- Initial version migrated from uala-modules-terraform
