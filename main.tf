data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config {
    bucket = "${var.cluster_state_bucket}"
    region = "eu-west-1"
    key    = "cloud-platform/${var.cluster_name}/terraform.tfstate"
  }
}

resource "random_id" "id" {
  byte_length = 8
}

locals {
  identifier = "cp-${random_id.id.hex}"
}

resource "aws_db_subnet_group" "default" {
  name       = "${local.identifier}"
  subnet_ids = ["${data.terraform_remote_state.cluster.internal_subnets_ids}"]

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }
}

resource "aws_security_group" "default" {
  count       = "${var.enabled == "true" ? 1 : 0}"
  name        = "${local.identifier}"
  description = "Allow all inbound traffic"
  vpc_id      = "${data.terraform_remote_state.cluster.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.terraform_remote_state.cluster.internal_subnets}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${data.terraform_remote_state.cluster.internal_subnets}"]
  }
}

# https://github.com/terraform-providers/terraform-provider-aws/issues/5218
resource "aws_iam_service_linked_role" "default" {
  count            = "${var.enabled == "true" && var.create_iam_service_linked_role == "true" ? 1 : 0}"
  aws_service_name = "es.amazonaws.com"
  description      = "AWSServiceRoleForAmazonElasticsearchService Service-Linked Role"
}

# Role that pods can assume for access to elasticsearch and kibana
resource "aws_iam_role" "elasticsearch_role" {
  count              = "${var.enabled == "true" ? 1 : 0}"
  name               = "${local.identifier}"
  description        = "IAM Role to assume to access the Elasticsearch ${local.identifier} cluster"
  assume_role_policy = "${join("", data.aws_iam_policy_document.assume_role.*.json)}"

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }
}

data "aws_iam_policy_document" "assume_role" {
  count = "${var.enabled == "true" ? 1 : 0}"

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    effect = "Allow"
  }
}

# resource "aws_iam_role_policy" "elasticsearch_role_policy" {
#   role = "${aws_iam_role.elasticsearch_role.id}"
#   statement {
#     actions = ["es:ESHttp*"]

#     resources = [
#       "${aws_elasticsearch_domain.default.arn}/*",
#       ]
#   }
# }

resource "aws_elasticsearch_domain" "default" {
  count                 = "${var.enabled == "true" ? 1 : 0}"
  domain_name           = "cloud-platform-${var.elasticsearch-domain}"
  elasticsearch_version = "${var.elasticsearch_version}"
  advanced_options      = "${var.advanced_options}"

  ebs_options {
    ebs_enabled = "${var.ebs_volume_size > 0 ? true : false}"
    volume_size = "${var.ebs_volume_size}"
    volume_type = "${var.ebs_volume_type}"
    iops        = "${var.ebs_iops}"
  }

  cluster_config {
    instance_count           = "${var.instance_count}"
    instance_type            = "${var.instance_type}"
    dedicated_master_enabled = "${var.dedicated_master_enabled}"
    dedicated_master_count   = "${var.dedicated_master_count}"
    dedicated_master_type    = "${var.dedicated_master_type}"
    zone_awareness_enabled   = "${var.zone_awareness_enabled}"

    zone_awareness_config {
      availability_zone_count = "${var.availability_zone_count}"
    }
  }

  vpc_options {
    security_group_ids = ["${aws_security_group.default.id}"]
    subnet_ids         = ["${data.terraform_remote_state.cluster.internal_subnets_ids}"]
  }

  snapshot_options {
    automated_snapshot_start_hour = "${var.automated_snapshot_start_hour}"
  }

  log_publishing_options {
    enabled                  = "${var.log_publishing_index_enabled }"
    log_type                 = "INDEX_SLOW_LOGS"
    cloudwatch_log_group_arn = "${var.log_publishing_index_cloudwatch_log_group_arn}"
  }

  log_publishing_options {
    enabled                  = "${var.log_publishing_search_enabled }"
    log_type                 = "SEARCH_SLOW_LOGS"
    cloudwatch_log_group_arn = "${var.log_publishing_search_cloudwatch_log_group_arn}"
  }

  log_publishing_options {
    enabled                  = "${var.log_publishing_application_enabled }"
    log_type                 = "ES_APPLICATION_LOGS"
    cloudwatch_log_group_arn = "${var.log_publishing_application_cloudwatch_log_group_arn}"
  }

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }

  depends_on = ["aws_iam_service_linked_role.default"]
}

data "aws_iam_policy_document" "default" {
  statement {
    actions = [
      "es:*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.elasticsearch_role.arn}"]
    }

    resources = [
      "${aws_elasticsearch_domain.default.arn}/*",
    ]
  }
}

resource "aws_elasticsearch_domain_policy" "default" {
  count           = "${var.enabled == "true" ? 1 : 0}"
  domain_name     = "es-${var.application}"
  access_policies = "${join("", data.aws_iam_policy_document.default.*.json)}"
}
