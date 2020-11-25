output "snapshot_role_arn" {
  description = "Snapshot role ARN"
  value       = length(aws_iam_role.snapshot_role) > 0 ? aws_iam_role.snapshot_role[0].arn : null
}
