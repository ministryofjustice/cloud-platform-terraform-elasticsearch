data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name == "live" ? "live-1" : var.vpc_name]
  }
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    SubnetType = "Private"
  }
}
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

resource "random_id" "id" {
  byte_length = 8
}

locals {
  identifier                   = "cloud-platform-${random_id.id.hex}"
  elasticsearch_domain_name    = length("${var.team_name}-${var.environment-name}-${var.elasticsearch-domain}") < 29 ? "${var.team_name}-${var.environment-name}-${var.elasticsearch-domain}" : var.elasticsearch-domain
  aws_es_irsa_sa_name          = var.aws_es_irsa_sa_name
  eks_cluster_oidc_issuer_url  = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  es_domain_policy_identifiers = module.iam_assumable_role_irsa_elastic_search.this_iam_role_arn
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

data "aws_iam_policy_document" "empty" {
}

# Common aws_iam_policy_document used by both assume and irsa
data "aws_iam_policy_document" "elasticsearch_role_policy" {
  source_policy_documents = var.s3_manual_snapshot_repository != "" ? [data.aws_iam_policy_document.elasticsearch_role_snapshot_policy[0].json] : [data.aws_iam_policy_document.empty.json]

  statement {
    actions = [
      "sts:AssumeRole",
      "es:ESHttp*",
    ]

    resources = ["${aws_elasticsearch_domain.elasticsearch_domain.arn}/*"]
  }
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
    warm_count               = var.warm_enabled == true ? var.warm_count : null
    warm_enabled             = var.warm_enabled
    warm_type                = var.warm_enabled == true ? var.warm_type : null
    zone_awareness_enabled   = var.zone_awareness_enabled
    zone_awareness_config {
      availability_zone_count = var.availability_zone_count
    }
    cold_storage_options {
      enabled = var.cold_enabled
    }
  }

  domain_endpoint_options {
    enforce_https       = var.domain_endpoint_enforce_https
    tls_security_policy = var.domain_endpoint_enforce_https == true ? "Policy-Min-TLS-1-2-2019-07" : null
  }

  vpc_options {
    security_group_ids = [aws_security_group.security_group.id]
    subnet_ids         = data.aws_subnets.private.ids
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

# Domain access policy to allow or deny access by IAM role ARN
data "aws_iam_policy_document" "iam_role_policy" {
  statement {
    actions = [
      "es:*",
    ]

    principals {
      type        = "AWS"
      identifiers = [local.es_domain_policy_identifiers]
    }

    resources = [
      "${aws_elasticsearch_domain.elasticsearch_domain.arn}/*",
    ]
  }
}

resource "time_sleep" "irsa_role_arn_creation" {
  create_duration = "10s"

  triggers = {
    # This sets up a proper dependency on the irsa service link role arn creation
    role_arn = module.iam_assumable_role_irsa_elastic_search.this_iam_role_arn
  }
}


resource "aws_elasticsearch_domain_policy" "domain_policy" {
  depends_on      = [time_sleep.irsa_role_arn_creation]
  domain_name     = local.elasticsearch_domain_name
  access_policies = join("", data.aws_iam_policy_document.iam_role_policy.*.json)
}

data "template_file" "ism_policy" {
  template = file("${path.module}/ism-policy.tpl.json")

  vars = {
    timestamp_field   = var.timestamp_field
    warm_transition   = var.warm_transition
    cold_transition   = var.cold_transition
    delete_transition = var.delete_transition
    index_pattern     = var.index_pattern
  }
}
