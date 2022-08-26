variable "cluster_name" {
  description = "The name of the cluster (eg.: cloud-platform-live-0)"
  type        = string
}

variable "team_name" {
  description = "The name of your development team"
  type        = string
}

variable "environment-name" {
  description = "The type of environment you're deploying to."
  type        = string
}

variable "application" {
  description = "The name of the application which uses this module."
  type        = string
}

variable "elasticsearch-domain" {
  description = "The name of the domain you want to use. The actual domain name will use the format <team_name>-<environment-name>-<elasticsearch-domain>"
  type        = string
}

variable "is-production" {
  description = "Whether the ElasticSearch cluster is for production use."
  default     = "false"
  type        = string
}

variable "business-unit" {
  description = "Area of the MOJ responsible for the service"
  default     = "mojdigital"
  type        = string
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
  type        = string
}

variable "namespace" {
  description = "Namespace from which the module is requested"
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
