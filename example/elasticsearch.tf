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
  source                 = "../"
  cluster_name           = "${var.cluster_name}"
  cluster_state_bucket   = "${var.cluster_state_bucket}"
  team_name              = "example-repo"
  business-unit          = "example-bu"
  application            = "exampleapp"
  is-production          = "false"
  environment-name       = "dev"
  infrastructure-support = "cloud-platform"
  elasticsearch-domain   = "example-es"
  namespace              = "poornima-dev"
}

resource "kubernetes_secret" "example_team_es" {
  metadata {
    name      = "example-team-es-cluster-output"
    namespace = "poornima-dev"
  }

  data {
    es_domain_arn   = "${module.example_team_es.domain_arn}"
    domain_id       = "${module.example_team_es.domain_id}"
    domain_endpoint = "${module.example_team_es.domain_endpoint}"
    kibana_endpoint = "${module.example_team_es.kibana_endpoint}"
    iam_role_name   = "${module.example_team_es.iam_role_name}"
    iam_role_arn    = "${module.example_team_es.iam_role_arn}"
  }
}
