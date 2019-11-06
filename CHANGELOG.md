## 2.10
### Updated
- Tag all resources

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
