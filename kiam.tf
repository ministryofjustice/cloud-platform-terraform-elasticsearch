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