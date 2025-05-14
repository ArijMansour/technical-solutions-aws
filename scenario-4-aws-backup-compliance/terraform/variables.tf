variable "name" {
  description = "Name prefix for all backup resources"
  type        = string
  default     = "backup"
}

variable "primary_region" {
  description = "Primary region for backups"
  type        = string
  default     = "eu-central-1"
}

variable "copy_region" {
  description = "Region for cross-region copy"
  type        = string
  default     = "eu-west-1"
}


# in the architecture the backup account ID was not provided.
# The module supports this feature by setting the backup_account_id variable.
variable "backup_account_id" {
  description = "Destination account ID for cross-account copy"
  type        = string
  default     = ""
}

variable "backup_schedule" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "cron(0 1 * * ? *)" # Daily at 1 AM
}

variable "retention_days" {
  description = "Number of days to retain recovery points"
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to encrypt backups"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to vaults and recovery points"
  type        = map(string)
  default     = {
    Owner    = "owner@eulerhermes.com"
    ToBackup = "true"
  }
}