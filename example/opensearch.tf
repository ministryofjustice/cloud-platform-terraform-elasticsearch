
/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */
module "example_team_es" {
  # source                        = "github.com/ministryofjustice/cloud-platform-terraform-opensearch?ref=4.0.0"
  source                          = "../"
  eks_cluster_name                = var.eks_cluster_name
  vpc_name                        = var.vpc_name
  team_name                       = var.team_name
  business-unit                   = var.business_unit
  application                     = var.application
  is-production                   = var.is_production
  environment-name                = var.environment
  infrastructure-support          = var.infrastructure_support
  namespace                       = var.namespace
  encryption_at_rest              = true
  node_to_node_encryption_enabled = true
  domain_endpoint_enforce_https   = true
  opensearch-domain               = "example-os"

  # change the opensearch version as you see fit.
  engine_version = "OpenSearch_1.1"

  # This will enable creation of manual snapshot in s3 repo, provide the "s3 bucket arn" to create snapshot in s3.
  # s3_manual_snapshot_repository = "s3-bucket-arn"

}

/*
 * This requires larger hot nodes, dedicated masters, warm nodes, so is much more expensive; useful only for huge amounts of archivable data (eg logs).
 * 
 */
module "example_cold_storage" {
  # source                 = "github.com/ministryofjustice/cloud-platform-terraform-opensearch?ref=4.0.0"
  source                          = "../"
  eks_cluster_name                = var.eks_cluster_name
  vpc_name                        = var.vpc_name
  team_name                       = var.team_name
  business-unit                   = var.business_unit
  application                     = var.application
  is-production                   = var.is_production
  environment-name                = var.environment
  infrastructure-support          = var.infrastructure_support
  namespace                       = var.namespace
  encryption_at_rest              = true
  node_to_node_encryption_enabled = true
  domain_endpoint_enforce_https   = true
  opensearch-domain               = "example-os"
  engine_version                  = "OpenSearch_1.1"

  # This will enable creation of manual snapshot in s3 repo, provide the "s3 bucket arn" to create snapshot in s3.
  # s3_manual_snapshot_repository = "s3-bucket-arn"

  instance_count           = 5
  instance_type            = "r6g.large.search"
  zone_awareness_enabled   = "true"
  availability_zone_count  = 3
  ebs_volume_size          = 20
  ebs_volume_type          = "gp3"
  ebs_iops                 = 3000
  dedicated_master_enabled = "true"
  dedicated_master_type    = "m6g.large.search"
  warm_enabled             = "true"
  cold_enabled             = "true"
  # this is used by the index policies for transition to warm/cold
  timestamp_field          = "last_updated"
  index_pattern            = "test_data*"
}

/*
 *There is no support for ISM in tf yet, the index pattern and policy per the output below must be created in Kibana manually
 *
 */
output "ism_policy" {
  value = module.example_cold_storage.ism_policy
}
