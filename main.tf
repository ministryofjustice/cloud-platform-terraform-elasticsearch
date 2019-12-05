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

resource "aws_db_subnet_group" "db_subnet" {
  name       = local.identifier
  subnet_ids = data.terraform_remote_state.cluster.outputs.internal_subnets_ids

  tags = {
    business-unit          = var.business-unit
    application            = var.application
    is-production          = var.is-production
    environment-name       = var.environment-name
    owner                  = var.team_name
    infrastructure-support = var.infrastructure-support
  }
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
  statement {
    actions = [
      "sts:AssumeRole",
      "es:ESHttp*",
    ]

    resources = ["${aws_elasticsearch_domain.elasticsearch_domain[0].arn}/*"]
  }
}

resource "aws_iam_role_policy" "elasticsearch_role_policy" {
  name   = local.identifier
  role   = aws_iam_role.elasticsearch_role[0].id
  policy = data.aws_iam_policy_document.elasticsearch_role_policy.json
}

resource "null_resource" "es_ns_annotation" {
  provisioner "local-exec" {
    command = "kubectl annotate namespace ${var.namespace} 'iam.amazonaws.com/permitted=${local.identifier}' --overwrite"
  }
}

resource "aws_elasticsearch_domain" "elasticsearch_domain" {
  count                 = var.enabled == "true" ? 1 : 0
  domain_name           = "${var.team_name}-${var.environment-name}-${var.elasticsearch-domain}"
  elasticsearch_version = var.elasticsearch_version
  advanced_options      = var.advanced_options

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

  tags = {
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
    replicas = 1

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

