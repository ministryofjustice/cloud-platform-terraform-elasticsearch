data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket = var.cluster_state_bucket
    region = "eu-west-1"
    key    = "cloud-platform/${var.cluster_name}/terraform.tfstate"
  }
}

resource "random_id" "id" {
  byte_length = 8
}

locals {
  identifier = "cloud-platform-${random_id.id.hex}"
}

resource "aws_security_group" "security_group" {
  count       = var.enabled == "true" ? 1 : 0
  name        = local.identifier
  description = "Allow all inbound traffic"
  vpc_id      = data.terraform_remote_state.cluster.outputs.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.terraform_remote_state.cluster.outputs.internal_subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.terraform_remote_state.cluster.outputs.internal_subnets
  }
}

# https://github.com/terraform-providers/terraform-provider-aws/issues/5218

# Role that pods can assume for access to elasticsearch and kibana
resource "aws_iam_role" "elasticsearch_role" {
  count              = var.enabled == "true" ? 1 : 0
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
  count = var.enabled == "true" ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nodes.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"]
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

    resources = ["${aws_elasticsearch_domain.elasticsearch_domain[0].arn}/*"]
  }
}

data "aws_iam_policy_document" "elasticsearch_role_snapshot_policy" {
  count = var.enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0
  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = ["${aws_iam_role.snapshot_role[0].arn}"]
  }
}

data "aws_iam_policy_document" "empty" {
}

resource "aws_iam_role_policy" "elasticsearch_role_policy" {
  name   = local.identifier
  role   = aws_iam_role.elasticsearch_role[0].id
  policy = data.aws_iam_policy_document.elasticsearch_role_policy.json
}


# Role that ES can assume for creating/restoring from manual snapshots
resource "aws_iam_role" "snapshot_role" {
  count              = var.enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0
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
  count = var.enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0

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
  count = var.enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = ["${var.s3_manual_snapshot_repository}"]
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
  count  = var.enabled == "true" && var.s3_manual_snapshot_repository != "" ? 1 : 0
  name   = "${local.identifier}-snapshots"
  role   = aws_iam_role.snapshot_role[0].id
  policy = data.aws_iam_policy_document.snapshot_role_policy[0].json
}

resource "null_resource" "es_ns_annotation" {
  provisioner "local-exec" {
    command = "kubectl annotate namespace ${var.namespace} 'iam.amazonaws.com/permitted=${local.identifier}' --overwrite"
  }
}

resource "aws_kms_key" "kms" {
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
  name          = "alias/${local.identifier}"
  target_key_id = aws_kms_key.kms[0].key_id
}

resource "aws_elasticsearch_domain" "elasticsearch_domain" {
  count                 = var.enabled == "true" ? 1 : 0
  domain_name           = "${var.team_name}-${var.environment-name}-${var.elasticsearch-domain}"
  elasticsearch_version = var.elasticsearch_version
  advanced_options      = var.advanced_options

  encrypt_at_rest_enabled    = var.encryption_at_rest
  encrypt_at_rest_kms_key_id = aws_kms_key.kms[0].arn
  node_to_node_encryption_enabled = var.node_to_node_encryption_enabled

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
    security_group_ids = [aws_security_group.security_group[0].id]
    subnet_ids         = data.terraform_remote_state.cluster.outputs.internal_subnets_ids
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
      identifiers = [aws_iam_role.elasticsearch_role[0].arn]
    }

    resources = [
      "${aws_elasticsearch_domain.elasticsearch_domain[0].arn}/*",
    ]
  }
}

resource "aws_elasticsearch_domain_policy" "domain_policy" {
  count           = var.enabled == "true" ? 1 : 0
  domain_name     = "${var.team_name}-${var.environment-name}-${var.elasticsearch-domain}"
  access_policies = join("", data.aws_iam_policy_document.iam_role_policy.*.json)
}

resource "kubernetes_deployment" "aws-es-proxy" {
  count = var.enabled == "true" ? 1 : 0

  metadata {
    name      = "aws-es-proxy"
    namespace = var.namespace

    labels = {
      app = "aws-es-proxy"
    }
  }

  spec {
    replicas = var.aws-es-proxy-replica-count

    selector {
      match_labels = {
        app = "aws-es-proxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "aws-es-proxy"
        }

        annotations = {
          "iam.amazonaws.com/role" = local.identifier
        }
      }

      spec {
        container {
          image = "ministryofjustice/cloud-platform-tools:aws-es-proxy"
          name  = "aws-es-proxy"

          port {
            container_port = 9200
          }

          args = ["-endpoint", format(
            "https://%s",
            aws_elasticsearch_domain.elasticsearch_domain[0].endpoint,
          ), "-listen", ":9200"]
        }
      }
    }
  }
}

resource "kubernetes_service" "aws-es-proxy-service" {
  count = var.enabled == "true" ? 1 : 0

  metadata {
    name      = "aws-es-proxy-service"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "aws-es-proxy"
    }

    port {
      port        = 9200
      target_port = 9200
    }
  }
}

