# IRSA

module "iam_assumable_role_irsa_elastic_search" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.13.0"
  create_role                   = var.irsa_enabled ? true : false
  role_name                     = "${local.identifier}-irsa"
  provider_url                  = local.eks_cluster_oidc_issuer_url
  role_policy_arns              = [var.irsa_enabled ? aws_iam_policy.irsa_elastic_search.0.arn : ""]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.namespace}:${var.aws_es_irsa_sa_name}"]
}

resource "aws_iam_policy" "irsa_elastic_search" {
  count = var.irsa_enabled == "true" ? 1 : 0

  name_prefix = local.identifier
  description = "EKS CloudWatch Exporter policy for es ${local.elasticsearch_domain_name}"
  policy      = data.aws_iam_policy_document.elasticsearch_role_policy.json
}

resource "kubernetes_service_account" "irsa_elastic_search_sa" {
  count = var.irsa_enabled == "true" ? 1 : 0
  metadata {
    name      = var.aws_es_irsa_sa_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_irsa_elastic_search.this_iam_role_arn
    }
  }
  automount_service_account_token = true
}