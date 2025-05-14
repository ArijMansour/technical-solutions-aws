# IAM role for AWS Backup service
resource "aws_iam_role" "backup_service" {
  provider = aws.primary
  name     = "${var.name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "backup.amazonaws.com" }
      }
    ]
  })
}

# Attach AWS managed service policy for backup
resource "aws_iam_role_policy_attachment" "for_backup" {
  provider   = aws.primary
  role       = aws_iam_role.backup_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# Policy for backup restoration
resource "aws_iam_role_policy_attachment" "for_restore" {
  provider   = aws.primary
  role       = aws_iam_role.backup_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Cross-account policy 
resource "aws_iam_role_policy_attachment" "cross_account_policy" {
  count      = var.backup_account_id != "" ? 1 : 0
  provider   = aws.primary
  role       = aws_iam_role.backup_service.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupCrossAccountBackupPolicy"
}