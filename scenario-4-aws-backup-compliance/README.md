# AWS Backup Terraform Module

This Terraform module implements an AWS Backup solution following specific architectural requirements for a cloud backup policy. The module provides cross-region backup capabilities with vault locking (WORM protection) as specified in the architecture.

## Features

- Primary backup vault in Frankfurt (eu-central-1) with vault lock
- Cross-region copy to Ireland (eu-west-1) with vault lock
- Support for cross-account backup 
- Resource selection based on tags
- Appropriate IAM roles and policies

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |

## Usage

### Without Remote Backend

To test this module without a remote backend:

1. Clone this repository
2. Remove or comment out the S3 backend configuration in `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
  
  # Comment out the following backend configuration to use local state
  # backend "s3" {
  #   bucket         = "terraform-state-backup-module"
  #   key            = "aws-backup/terraform.tfstate"
  #   region         = "eu-west-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock-backup-module"
  # }
}
```

3. Initialize Terraform:
```bash
terraform init
```

4. Review the execution plan:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform apply
```

6. To destroy the resources when done:
```bash
terraform destroy
```

### Testing The Backup Solution

After applying the Terraform configuration:

1. Go to the AWS Management Console
2. Navigate to AWS Backup service
3. Verify the backup vaults were created:
   - Primary vault in Frankfurt (eu-central-1)
   - Copy vault in Ireland (eu-west-1)
4. Check that both vaults have vault lock enabled
5. Verify the backup plan was created
6. Tag any AWS resource with `ToBackup=true` and `Owner=owner@eulerhermes.com`
7. Wait for the scheduled backup or create an on-demand backup
8. Verify that the backup is created and copied to the secondary region

## Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| name | Prefix for resource names | string | "backup" |
| primary_region | Primary region (Frankfurt) | string | "eu-central-1" |
| copy_region | Region for cross-region copy (Ireland) | string | "eu-west-1" |
| backup_account_id | Destination account ID for cross-account copy | string | "" |
| backup_schedule | Cron expression for backup schedule | string | "cron(0 1 * * ? *)" |
| retention_days | Number of days to retain backups | number | 30 |
| max_retention_days | Maximum retention days for vault lock | number | 60 |
| changeable_for_days | Days before vault lock becomes immutable | number | 3 |
| tags | Tags to apply to resources | map(string) | `{ Owner = "owner@eulerhermes.com.com", ToBackup = "true" }` |

## Outputs

| Name | Description |
|------|-------------|
| backup_plan_id | ID of the created backup plan |
| primary_vault_name | Name of the primary backup vault |
| copy_vault_name | Name of the copy region backup vault |
| backup_iam_role_arn | ARN of the IAM role for AWS Backup |

## Architecture

This module implements the following architecture:

1. A primary AWS account with:
   - Backup vault with WORM protection in Frankfurt
   - Backup vault with WORM protection in Ireland
   - Backup plan in Frankfurt

2. Support for cross-account backup to a separate backup account (when configured)

## Notes

- Resource selection is based on tags `ToBackup=true` and `Owner=owner@eulerhermes.com`
- Cross-account backup requires setting the `backup_account_id` variable
- The module doesn't create the backup account it must exist already if cross-account backup is enabled