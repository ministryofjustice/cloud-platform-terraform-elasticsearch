variable "aws_region" {
  description = "Region into which the resource will be created."
  default     = "eu-west-2"
}

variable "cluster_name" {
  description = "The name of the cluster (eg.: cloud-platform-live-0)"
}

variable "cluster_state_bucket" {
  description = "The name of the S3 bucket holding the terraform state for the cluster"
}

variable "team_name" {
  description = "The name of your development team"
}

variable "environment-name" {
  description = "The type of environment you're deploying to."
}

variable "application" {
  description = "The name of the application which uses this module."
}

variable "elasticsearch-domain" {
  description = "The name of the domain you want to use. The actual domain name will use the format <team_name>-<environment-name>-<elasticsearch-domain>"
}

variable "is-production" {
  default = "false"
}

variable "business-unit" {
  description = "Area of the MOJ responsible for the service"
  default     = "mojdigital"
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
}

variable "namespace" {
  description = "Namespace from which the module is requested"
}

variable "iam_role_arns" {
  type        = "list"
  default     = []
  description = "List of IAM role ARNs to permit access to the Elasticsearch domain"
}

variable "iam_authorizing_role_arns" {
  type        = "list"
  default     = []
  description = "List of IAM role ARNs to permit to assume the Elasticsearch user role"
}

variable "enabled" {
  type        = "string"
  default     = "true"
  description = "Set to false to prevent the module from creating any resources"
}

variable "elasticsearch_version" {
  type        = "string"
  default     = "7.1"
  description = "Version of Elasticsearch to deploy"
}

variable "instance_type" {
  type        = "string"
  default     = "t2.small.elasticsearch"
  description = "Elasticsearch instance type for data nodes in the cluster"
}

variable "instance_count" {
  description = "Number of data nodes in the cluster"
  default     = 3
}

variable "zone_awareness_enabled" {
  type        = "string"
  default     = "true"
  description = "Enable zone awareness for Elasticsearch cluster"
}

variable "availability_zone_count" {
  default     = 3
  description = "Number of Availability Zones for the domain to use."
}

variable "ebs_volume_size" {
  description = "Optionally use EBS volumes for data storage by specifying volume size in GB"
  default     = 10
}

variable "ebs_volume_type" {
  type        = "string"
  default     = "gp2"
  description = "Storage type of EBS volumes"
}

variable "ebs_iops" {
  default     = 0
  description = "The baseline input/output (I/O) performance of EBS volumes attached to data nodes. Applicable only for the Provisioned IOPS EBS volume type"
}

variable "log_publishing_index_enabled" {
  type        = "string"
  default     = "false"
  description = "Specifies whether log publishing option for INDEX_SLOW_LOGS is enabled or not"
}

variable "log_publishing_search_enabled" {
  type        = "string"
  default     = "false"
  description = "Specifies whether log publishing option for SEARCH_SLOW_LOGS is enabled or not"
}

variable "log_publishing_application_enabled" {
  type        = "string"
  default     = "false"
  description = "Specifies whether log publishing option for ES_APPLICATION_LOGS is enabled or not"
}

variable "log_publishing_index_cloudwatch_log_group_arn" {
  type        = "string"
  default     = ""
  description = "ARN of the CloudWatch log group to which log for INDEX_SLOW_LOGS needs to be published"
}

variable "log_publishing_search_cloudwatch_log_group_arn" {
  type        = "string"
  default     = ""
  description = "ARN of the CloudWatch log group to which log for SEARCH_SLOW_LOGS  needs to be published"
}

variable "log_publishing_application_cloudwatch_log_group_arn" {
  type        = "string"
  default     = ""
  description = "ARN of the CloudWatch log group to which log for ES_APPLICATION_LOGS needs to be published"
}

variable "automated_snapshot_start_hour" {
  description = "Hour at which automated snapshots are taken, in UTC"
  default     = 0
}

variable "dedicated_master_enabled" {
  type        = "string"
  default     = "false"
  description = "Indicates whether dedicated master nodes are enabled for the cluster"
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes in the cluster"
  default     = 0
}

variable "dedicated_master_type" {
  type        = "string"
  default     = "t2.small.elasticsearch"
  description = "Instance type of the dedicated master nodes in the cluster"
}

variable "advanced_options" {
  type        = "map"
  default     = {}
  description = "Key-value string pairs to specify advanced configuration options"
}

variable "kibana_subdomain_name" {
  type        = "string"
  default     = "kibana"
  description = "The name of the subdomain for Kibana in the DNS zone (_e.g._ `kibana`, `ui`, `ui-es`, `search-ui`, `kibana.elasticsearch`)"
}

variable "create_iam_service_linked_role" {
  type        = "string"
  default     = "false"
  description = "Whether to create `AWSServiceRoleForAmazonElasticsearchService` service-linked role. Set it to `false` if you already have an ElasticSearch cluster created in the AWS account and AWSServiceRoleForAmazonElasticsearchService already exists. See https://github.com/terraform-providers/terraform-provider-aws/issues/5218 for more info"
}

variable "node_to_node_encryption_enabled" {
  type        = "string"
  default     = "false"
  description = "Whether to enable node-to-node encryption"
}

variable "create_aws_es_proxy" {
  type        = "string"
  default     = "true"
  description = "Whether to create HTTP Proxy for accessing Elasticsearch and Kibana outside of the cluster"
}
