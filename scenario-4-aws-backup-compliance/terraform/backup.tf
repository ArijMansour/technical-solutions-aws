# Primary backup vault
resource "aws_backup_vault" "primary" {
  provider    = aws.primary
  name        = "${var.name}-vault"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

# WORM lock for primary vault
resource "aws_backup_vault_lock_configuration" "primary_lock" {
  provider            = aws.primary
  backup_vault_name   = aws_backup_vault.primary.name
  min_retention_days  = var.retention_days
  max_retention_days  = var.retention_days * 2
  changeable_for_days = 3
}

# Copy region backup vault
resource "aws_backup_vault" "copy" {
  provider    = aws.copy_region
  name        = "${var.name}-vault-copy"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

# WORM lock for copy vault
resource "aws_backup_vault_lock_configuration" "copy_lock" {
  provider            = aws.copy_region
  backup_vault_name   = aws_backup_vault.copy.name
  min_retention_days  = var.retention_days
  max_retention_days  = var.retention_days * 2
  changeable_for_days = 3
}

# AWS Backup plan with rules and copy actions
resource "aws_backup_plan" "main" {
  provider = aws.primary
  name     = "${var.name}-plan"

  rule {
    rule_name         = "${var.name}-rule"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = var.backup_schedule

    # Retention configuration
    lifecycle {
      delete_after = var.retention_days
    }

    # Tags to apply to recovery points
    recovery_point_tags = var.tags

    # Cross-region copy action
    copy_action {
      destination_vault_arn = aws_backup_vault.copy.arn
      lifecycle {
        delete_after = var.retention_days
      }
    }

    # Cross-account copy action (if account ID provided)
    dynamic "copy_action" {
      for_each = var.backup_account_id != "" ? [1] : []
      content {
        destination_vault_arn = "arn:aws:backup:${var.primary_region}:${var.backup_account_id}:backup-vault:${var.name}-vault"
        lifecycle {
          delete_after = var.retention_days
        }
      }
    }
  }

  tags = var.tags
}

# Resource selection for backup
resource "aws_backup_selection" "tagged_resources" {
  provider     = aws.primary
  name         = "${var.name}-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup_service.arn

  # Select resources by tag
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "ToBackup"
    value = "true"
  }
}