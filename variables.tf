#################
# Configuration #
#################
variable "eks_cluster_name" {
  description = "The name of the eks cluster to retrieve the OIDC information"
  type        = string
}

variable "vpc_name" {
  description = "The name of the vpc (eg.: live-1)"
  type        = string
}

variable "elasticsearch-domain" {
  description = "The name of the domain you want to use. The actual domain name will use the format <team_name>-<environment-name>-<elasticsearch-domain>"
  type        = string
}

variable "snapshot_enabled" {
  type        = string
  default     = "true"
  description = "Set to false to prevent the module from creating snapshot resources"
}

variable "elasticsearch_version" {
  type        = string
  default     = "7.10"
  description = "Version of Elasticsearch to deploy"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium.elasticsearch"
  description = "Elasticsearch instance type for data nodes in the cluster"
}

variable "instance_count" {
  description = "Total data nodes in the cluster, includes warm"
  default     = 3
  type        = number
}

variable "warm_count" {
  description = "Number of warm data nodes in the cluster"
  default     = 2
  type        = number
}

variable "warm_type" {
  type        = string
  default     = "ultrawarm1.medium.elasticsearch"
  description = "Elasticsearch instance type for warm data nodes in the cluster"
}

variable "warm_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable warm storage"
}

variable "warm_transition" {
  type        = string
  default     = "7d"
  description = "Time until transition to warm storage"
}

variable "cold_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable cold storage"
}

variable "cold_transition" {
  type        = string
  default     = "30d"
  description = "Time until transition to cold storage"
}

variable "delete_transition" {
  type        = string
  default     = "365d"
  description = "Time until indexes are permanently deleted"
}

variable "timestamp_field" {
  type        = string
  default     = "last_updated"
  description = "Field Kibana identifies as Time field, when creating the index pattern"
}

variable "index_pattern" {
  type        = string
  default     = "test_data*"
  description = "Pattern created in Kibana, policy will apply to matching new indices"
}

variable "zone_awareness_enabled" {
  type        = bool
  default     = true
  description = "Enable zone awareness for Elasticsearch cluster"
}

variable "availability_zone_count" {
  default     = 3
  description = "Number of Availability Zones for the domain to use."
  type        = number
}

variable "ebs_volume_size" {
  description = "Optionally use EBS volumes for data storage by specifying volume size in GB"
  default     = 10
  type        = number
}

variable "ebs_volume_type" {
  type        = string
  default     = "gp3"
  description = "Storage type of EBS volumes"
}

variable "ebs_iops" {
  default     = 3000
  description = "The baseline input/output (I/O) performance of EBS volumes attached to data nodes. Applicable only for the Provisioned IOPS EBS volume type"
  type        = number
}

variable "log_publishing_index_enabled" {
  type        = string
  default     = "false"
  description = "Specifies whether log publishing option for INDEX_SLOW_LOGS is enabled or not"
}

variable "log_publishing_search_enabled" {
  type        = string
  default     = "false"
  description = "Specifies whether log publishing option for SEARCH_SLOW_LOGS is enabled or not"
}

variable "log_publishing_application_enabled" {
  type        = string
  default     = "false"
  description = "Specifies whether log publishing option for ES_APPLICATION_LOGS is enabled or not"
}

variable "log_publishing_index_cloudwatch_log_group_arn" {
  type        = string
  default     = ""
  description = "ARN of the CloudWatch log group to which log for INDEX_SLOW_LOGS needs to be published"
}

variable "log_publishing_search_cloudwatch_log_group_arn" {
  type        = string
  default     = ""
  description = "ARN of the CloudWatch log group to which log for SEARCH_SLOW_LOGS  needs to be published"
}

variable "log_publishing_application_cloudwatch_log_group_arn" {
  type        = string
  default     = ""
  description = "ARN of the CloudWatch log group to which log for ES_APPLICATION_LOGS needs to be published"
}

variable "automated_snapshot_start_hour" {
  description = "Hour at which automated snapshots are taken, in UTC"
  default     = 0
  type        = number
}

variable "dedicated_master_enabled" {
  type        = string
  default     = "false"
  description = "Indicates whether dedicated master nodes are enabled for the cluster"
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes in the cluster"
  default     = 3
  type        = number
}

variable "dedicated_master_type" {
  type        = string
  default     = "t3.small.elasticsearch"
  description = "Instance type of the dedicated master nodes in the cluster"
}

variable "advanced_options" {
  type        = map(string)
  default     = {}
  description = "Key-value string pairs to specify advanced configuration options"
}

variable "node_to_node_encryption_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable node-to-node encryption"
}

variable "encryption_at_rest" {
  type        = bool
  default     = false
  description = "Whether to encrypt the domain at rest"
}

variable "aws_es_proxy_service_name" {
  type        = string
  default     = "aws-es-proxy-service"
  description = "Name used by aws-es-proxy service"
}

variable "aws_es_irsa_sa_name" {
  type        = string
  default     = "aws-es-irsa-sa"
  description = "Name used by aws-es irsa service account"
}

variable "aws-es-proxy-replica-count" {
  type        = number
  default     = 1
  description = "Number of replicas for the aws-es-proxy deployment"
}

variable "s3_manual_snapshot_repository" {
  type        = string
  default     = ""
  description = "ARN of S3 bucket to use for manual snapshot repository"
}

variable "domain_endpoint_enforce_https" {
  type        = bool
  default     = false
  description = "Enforce HTTPS when connecting to the cluster's domain endpoint"
}

variable "auto_tune_config" {
  type = object({
    desired_state                  = string
    start_at                       = string
    duration_value                 = number
    duration_unit                  = string
    cron_expression_for_recurrence = string
    rollback_on_disable            = string
  })
  default     = null
  description = "see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticsearch_domain#auto_tune_options for object structure"
}

########
# Tags #
########
variable "business_unit" {
  description = "Area of the MOJ responsible for the service"
  type        = string
}

variable "application" {
  description = "Application name"
  type        = string
}

variable "is_production" {
  description = "Whether this is used for production or not"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "namespace" {
  description = "Namespace name"
  type        = string
}

variable "environment_name" {
  description = "Environment name"
  type        = string
}

variable "infrastructure_support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
  type        = string
}
