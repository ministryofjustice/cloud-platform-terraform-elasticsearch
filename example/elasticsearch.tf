/*
 * When using this module through the cloud-platform-environments, the following
 * two variables are automatically supplied by the pipeline.
 *
 */

variable "cluster_name" {}

variable "cluster_state_bucket" {}

/*
 * Make sure that you use the latest version of the module by changing the
 * `ref=` value in the `source` attribute to the latest version listed on the
 * releases page of this repository.
 *
 */
module "example_team_es" {
  source               = "../"
  cluster_name         = "${var.cluster_name}"
  cluster_state_bucket = "${var.cluster_state_bucket}"
  team_name            = "example-repo"
  business-unit        = "example-bu"
  application          = "exampleapp"
  is-production        = "false"
  environment-name     = "dev"
  infrastructure-support = "cloud-platform"
  elasticsearch-domain = "example-es"


}
