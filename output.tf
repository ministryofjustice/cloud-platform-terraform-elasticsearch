output "domain_arn" {
  value       = "${join("", aws_elasticsearch_domain.default.*.arn)}"
  description = "ARN of the Elasticsearch domain"
}

output "domain_endpoint" {
  value       = "${join("", aws_elasticsearch_domain.default.*.endpoint)}"
  description = "Domain-specific endpoint used to submit index, search, and data upload requests"
}

output "kibana_endpoint" {
  value       = "${join("", aws_elasticsearch_domain.default.*.kibana_endpoint)}"
  description = "Domain-specific endpoint for Kibana without https scheme"
}

output "iam_role_name" {
  value       = "${join(",", aws_iam_role.elasticsearch_role.*.name)}"
  description = "The name of the IAM role to allow access to Elasticsearch cluster"
}

output "iam_role_arn" {
  value       = "${join(",",aws_iam_role.elasticsearch_role.*.arn)}"
  description = "The ARN of the IAM role to allow access to Elasticsearch cluster"
}
