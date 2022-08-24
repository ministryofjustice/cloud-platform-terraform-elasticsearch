/*
 * When using this module through the cloud-platform-environments,
 * this variable is automatically supplied by the pipeline.
 *
*/

variable "cluster_name" {
}

/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */
module "example_team_es" {
  # source                 = "github.com/ministryofjustice/cloud-platform-terraform-elasticsearch?ref=3.9.5"
  source = "../"
  cluster_name           = var.cluster_name
  application            = "exampleapp"
  business-unit          = "example-bu"
  environment-name       = "dev"
  infrastructure-support = "cloud-platform@digital.justice.gov.uk"
  is-production          = "false"
  team_name              = "example-team"
  elasticsearch-domain   = "example-es"
  namespace              = "my-namespace"

  # change the elasticsearch version as you see fit.
  elasticsearch_version = "7.10"

  # This will enable creation of manual snapshot in s3 repo, provide the "s3 bucket arn" to create snapshot in s3.
  # s3_manual_snapshot_repository = "s3-bucket-arn"

  providers = {
    aws = aws.london
  }
}

