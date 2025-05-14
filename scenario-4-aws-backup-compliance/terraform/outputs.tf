output "backup_plan_id" {
  description = "ID of the AWS Backup Plan"
  value       = aws_backup_plan.main.id
}

output "primary_vault_name" {
  description = "Name of the primary backup vault"
  value       = aws_backup_vault.primary.name
}

output "copy_vault_name" {
  description = "Name of the copy region backup vault"
  value       = aws_backup_vault.copy.name
}

output "backup_iam_role_arn" {
  description = "ARN of the IAM role used for AWS Backup"
  value       = aws_iam_role.backup_service.arn
}