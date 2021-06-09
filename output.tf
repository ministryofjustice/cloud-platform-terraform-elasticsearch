output "aws_es_proxy_url" {
  description = "URL for aws-es-proxy service"
  value       = length(kubernetes_service.aws-es-proxy-service) > 0 ? "http://${kubernetes_service.aws-es-proxy-service.metadata.0.name}:${kubernetes_service.aws-es-proxy-service.spec.0.port.0.port}" : ""
}

output "snapshot_role_arn" {
  description = "Snapshot role ARN"
  value       = length(aws_iam_role.snapshot_role) > 0 ? aws_iam_role.snapshot_role[0].arn : null
}

output "aws_iam_role_name" {
  description = "IAM role name to assume when accessing the Elasticsearch"
  value       = length(aws_iam_role.elasticsearch_role) > 0 ? aws_iam_role.elasticsearch_role[0].name : null
}
