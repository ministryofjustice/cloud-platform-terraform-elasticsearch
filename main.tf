data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.cluster_name == "live" ? "live-1" : var.cluster_name]
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.cluster_name}.cloud-platform.service.justice.gov.uk"
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnet" "private" {
  for_each = data.aws_subnet_ids.private.ids
  id       = each.value
}

resource "random_id" "id" {
  byte_length = 8
}

locals {
  identifier                = "cloud-platform-${random_id.id.hex}"
  elasticsearch_domain_name = "${var.team_name}-${var.environment-name}-${var.elasticsearch-domain}"
  aws_es_irsa_sa_name       = var.irsa_enabled ? var.aws_es_irsa_sa_name : null
  assume_role_name          = var.assume_enabled ? local.identifier : null
}

resource "aws_security_group" "security_group" {
  name        = local.identifier
  description = "Allow all inbound traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [for s in data.aws_subnet.private : s.cidr_block]
  }
}

# https://github.com/terraform-providers/terraform-provider-aws/issues/5218

# Role that pods can assume for access to elasticsearch and kibana
resource "aws_iam_role" "elasticsearch_role" {
  count              = var.assume_enabled == "true" ? 1 : 0
  name               = local.identifier
  description        = "IAM Role to assume to access the Elasticsearch -${var.elasticsearch-domain} cluster"
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role.*.json)

  tags = {
    namespace              = var.namespace
    business-unit          = var.business-unit
    application            = var.application
    is-production          = var.is-production
    environment-name       = var.environment-name
    owner                  = var.team_name
    infrastructure-support = var.infrastructure-support
  }
}

data "aws_iam_policy_document" "assume_role" {
  count = var.assume_enabled == "true" ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nodes.${data.aws_route53_zone.selected.name}"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "elasticsearch_role_policy" {
  source_json = var.s3_manual_snapshot_repository != "" ? data.aws_iam_policy_document.elasticsearch_role_snapshot_policy[0].json : data.aws_iam_policy_document.empty.json

  statement {
    actions = [
      "sts:AssumeRole",
      "es:ESHttp*",
    ]

    resources = ["${aws_elasticsearch_domain.elasticsearch_domain.arn}/*"]
  }
}

data "aws_iam_policy_document" "empty" {
}

resource "aws_iam_role_policy" "elasticsearch_role_policy" {
  count  = var.assume_enabled == "true" ? 1 : 0
  name   = local.identifier
  role   = aws_iam_role.elasticsearch_role[0].id
  policy = data.aws_iam_policy_document.elasticsearch_role_policy.json
}

# Role that ES can assume for creating/restoring from manual snapshots

data "aws_iam_policy_document" "elasticsearch_role_snapshot_policy" {
  count = var.snapshot_enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0
  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [aws_iam_role.snapshot_role[0].arn]
  }
}

resource "aws_iam_role" "snapshot_role" {
  count              = var.snapshot_enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0
  name               = "${local.identifier}-snapshots"
  description        = "IAM Role for Elasticsearch service to assume for creating and restoring manual snapshots with s3"
  assume_role_policy = join("", data.aws_iam_policy_document.snapshot_role.*.json)

  tags = {
    business-unit          = var.business-unit
    application            = var.application
    is-production          = var.is-production
    environment-name       = var.environment-name
    owner                  = var.team_name
    infrastructure-support = var.infrastructure-support
  }
}

data "aws_iam_policy_document" "snapshot_role" {
  count = var.snapshot_enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "snapshot_role_policy" {
  count = var.snapshot_enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [var.s3_manual_snapshot_repository]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = ["${var.s3_manual_snapshot_repository}/*"]
  }

}

resource "aws_iam_role_policy" "snapshot_role_policy" {
  count  = var.snapshot_enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0
  name   = "${local.identifier}-snapshots"
  role   = aws_iam_role.snapshot_role[0].id
  policy = data.aws_iam_policy_document.snapshot_role_policy[0].json
}

resource "aws_kms_key" "kms" {
  count       = var.encryption_at_rest ? 1 : 0
  description = local.identifier

  tags = {
    business-unit          = var.business-unit
    application            = var.application
    is-production          = var.is-production
    environment-name       = var.environment-name
    owner                  = var.team_name
    infrastructure-support = var.infrastructure-support
    namespace              = var.namespace
  }
}

resource "aws_kms_alias" "alias" {
  count         = var.encryption_at_rest ? 1 : 0
  name          = "alias/${local.identifier}"
  target_key_id = aws_kms_key.kms[0].key_id
}

resource "aws_elasticsearch_domain" "elasticsearch_domain" {
  domain_name           = local.elasticsearch_domain_name
  elasticsearch_version = var.elasticsearch_version
  advanced_options = merge({
    "rest.action.multi.allow_explicit_index" = "true"
  }, var.advanced_options)

  encrypt_at_rest {
    enabled    = var.encryption_at_rest
    kms_key_id = var.encryption_at_rest ? aws_kms_key.kms[0].arn : null
  }

  node_to_node_encryption {
    enabled = var.node_to_node_encryption_enabled
  }

  ebs_options {
    ebs_enabled = var.ebs_volume_size > 0 ? true : false
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
    iops        = var.ebs_iops
  }

  cluster_config {
    instance_count           = var.instance_count
    instance_type            = var.instance_type
    dedicated_master_enabled = var.dedicated_master_enabled
    dedicated_master_count   = var.dedicated_master_count
    dedicated_master_type    = var.dedicated_master_type
    zone_awareness_enabled   = var.zone_awareness_enabled

    zone_awareness_config {
      availability_zone_count = var.availability_zone_count
    }
  }

  vpc_options {
    security_group_ids = [aws_security_group.security_group.id]
    subnet_ids         = data.aws_subnet_ids.private.ids
  }

  snapshot_options {
    automated_snapshot_start_hour = var.automated_snapshot_start_hour
  }

  log_publishing_options {
    enabled                  = var.log_publishing_index_enabled
    log_type                 = "INDEX_SLOW_LOGS"
    cloudwatch_log_group_arn = var.log_publishing_index_cloudwatch_log_group_arn
  }

  log_publishing_options {
    enabled                  = var.log_publishing_search_enabled
    log_type                 = "SEARCH_SLOW_LOGS"
    cloudwatch_log_group_arn = var.log_publishing_search_cloudwatch_log_group_arn
  }

  log_publishing_options {
    enabled                  = var.log_publishing_application_enabled
    log_type                 = "ES_APPLICATION_LOGS"
    cloudwatch_log_group_arn = var.log_publishing_application_cloudwatch_log_group_arn
  }

  tags = {
    namespace              = var.namespace
    business-unit          = var.business-unit
    application            = var.application
    is-production          = var.is-production
    environment-name       = var.environment-name
    owner                  = var.team_name
    infrastructure-support = var.infrastructure-support
  }
}

data "aws_iam_policy_document" "iam_role_policy" {
  statement {
    actions = [
      "es:*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_elasticsearch_domain.elasticsearch_domain.arn}/*",
    ]
  }
}

resource "aws_elasticsearch_domain_policy" "domain_policy" {
  domain_name     = local.elasticsearch_domain_name
  access_policies = join("", data.aws_iam_policy_document.iam_role_policy.*.json)
}

resource "kubernetes_deployment" "aws-es-proxy" {

  metadata {
    name      = "aws-es-proxy-${local.identifier}"
    namespace = var.namespace

    labels = {
      app = "aws-es-proxy"
    }
  }

  spec {
    replicas = var.aws-es-proxy-replica-count

    selector {
      match_labels = {
        app = "aws-es-proxy-${local.identifier}"
      }
    }

    template {
      metadata {
        labels = {
          app = "aws-es-proxy-${local.identifier}"
        }

        annotations = {
          "iam.amazonaws.com/role" = local.assume_role_name
        }
      }

      spec {
        service_account_name = local.aws_es_irsa_sa_name
        container {
          image = "ministryofjustice/cloud-platform-tools:aws-es-proxy"
          name  = "aws-es-proxy"

          port {
            container_port = 9200
          }

          args = ["-endpoint", format(
            "https://%s",
            aws_elasticsearch_domain.elasticsearch_domain.endpoint,
          ), "-listen", ":9200"]
        }
      }
    }
  }
}

resource "kubernetes_service" "aws-es-proxy-service" {

  metadata {
    name      = var.aws_es_proxy_service_name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "aws-es-proxy-${local.identifier}"
    }

    port {
      port        = 9200
      target_port = 9200
    }
  }
}

# IRSA

module "iam_assumable_role_irsa_elastic_search" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.13.0"
  create_role                   = var.irsa_enabled ? true : false
  role_name                     = "${local.identifier}-irsa"
  provider_url                  = var.eks_cluster_oidc_issuer_url
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