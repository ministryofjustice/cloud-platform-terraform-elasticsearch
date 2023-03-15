# cloud-platform-terraform-elasticsearch
Terraform module to add a AWS Elasticsearch and Kibana resource in the Cloud Platform

[![Releases](https://img.shields.io/github/release/ministryofjustice/cloud-platform-terraform-elasticsearch/all.svg?style=flat-square)](https://github.com/ministryofjustice/cloud-platform-terraform-elasticsearch/releases)

Terraform module that will create an AWS Elasticsearch cluster within a VPC and a relevant IAM role that will provide access to the Elasticsearch.

The resources created will have a randomised name of the format `cloud-platform-7a5c4a2a7e2134a`. This ensures that the resources created is globally unique.

## Usage

For the most basic setup, see [the example](example/) folder. Also check the *Accessing* section below.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.27.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.12.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.27.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.12.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 2.0.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_assumable_role_irsa_elastic_search"></a> [iam\_assumable\_role\_irsa\_elastic\_search](#module\_iam\_assumable\_role\_irsa\_elastic\_search) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 3.13.0 |

## Resources

| Name | Type |
|------|------|
| [aws_elasticsearch_domain.elasticsearch_domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticsearch_domain) | resource |
| [aws_elasticsearch_domain_policy.domain_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticsearch_domain_policy) | resource |
| [aws_iam_policy.irsa_elastic_search](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.snapshot_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.snapshot_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_security_group.security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [kubernetes_deployment.aws-es-proxy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.aws-es-proxy-service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service_account.irsa_elastic_search_sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [time_sleep.irsa_role_arn_creation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_eks_cluster.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_policy_document.elasticsearch_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.elasticsearch_role_snapshot_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.empty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snapshot_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.snapshot_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [template_file.ism_policy](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_advanced_options"></a> [advanced\_options](#input\_advanced\_options) | Key-value string pairs to specify advanced configuration options | `map(string)` | `{}` | no |
| <a name="input_application"></a> [application](#input\_application) | The name of the application which uses this module. | `string` | n/a | yes |
| <a name="input_automated_snapshot_start_hour"></a> [automated\_snapshot\_start\_hour](#input\_automated\_snapshot\_start\_hour) | Hour at which automated snapshots are taken, in UTC | `number` | `0` | no |
| <a name="input_availability_zone_count"></a> [availability\_zone\_count](#input\_availability\_zone\_count) | Number of Availability Zones for the domain to use. | `number` | `3` | no |
| <a name="input_aws-es-proxy-replica-count"></a> [aws-es-proxy-replica-count](#input\_aws-es-proxy-replica-count) | Number of replicas for the aws-es-proxy deployment | `number` | `1` | no |
| <a name="input_aws_es_irsa_sa_name"></a> [aws\_es\_irsa\_sa\_name](#input\_aws\_es\_irsa\_sa\_name) | Name used by aws-es irsa service account | `string` | `"aws-es-irsa-sa"` | no |
| <a name="input_aws_es_proxy_service_name"></a> [aws\_es\_proxy\_service\_name](#input\_aws\_es\_proxy\_service\_name) | Name used by aws-es-proxy service | `string` | `"aws-es-proxy-service"` | no |
| <a name="input_business-unit"></a> [business-unit](#input\_business-unit) | Area of the MOJ responsible for the service | `string` | n/a | yes |
| <a name="input_cold_enabled"></a> [cold\_enabled](#input\_cold\_enabled) | Whether to enable cold storage | `bool` | `false` | no |
| <a name="input_cold_transition"></a> [cold\_transition](#input\_cold\_transition) | Time until transition to cold storage | `string` | `"30d"` | no |
| <a name="input_dedicated_master_count"></a> [dedicated\_master\_count](#input\_dedicated\_master\_count) | Number of dedicated master nodes in the cluster | `number` | `3` | no |
| <a name="input_dedicated_master_enabled"></a> [dedicated\_master\_enabled](#input\_dedicated\_master\_enabled) | Indicates whether dedicated master nodes are enabled for the cluster | `string` | `"false"` | no |
| <a name="input_dedicated_master_type"></a> [dedicated\_master\_type](#input\_dedicated\_master\_type) | Instance type of the dedicated master nodes in the cluster | `string` | `"t3.small.elasticsearch"` | no |
| <a name="input_delete_transition"></a> [delete\_transition](#input\_delete\_transition) | Time until indexes are permanently deleted | `string` | `"365d"` | no |
| <a name="input_domain_endpoint_enforce_https"></a> [domain\_endpoint\_enforce\_https](#input\_domain\_endpoint\_enforce\_https) | Enforce HTTPS when connecting to the cluster's domain endpoint | `bool` | `false` | no |
| <a name="input_ebs_iops"></a> [ebs\_iops](#input\_ebs\_iops) | The baseline input/output (I/O) performance of EBS volumes attached to data nodes. Applicable only for the Provisioned IOPS EBS volume type | `number` | `3000` | no |
| <a name="input_ebs_volume_size"></a> [ebs\_volume\_size](#input\_ebs\_volume\_size) | Optionally use EBS volumes for data storage by specifying volume size in GB | `number` | `10` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | Storage type of EBS volumes | `string` | `"gp3"` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | The name of the eks cluster to retrieve the OIDC information | `string` | n/a | yes |
| <a name="input_elasticsearch-domain"></a> [elasticsearch-domain](#input\_elasticsearch-domain) | The name of the domain you want to use. The actual domain name will use the format <team\_name>-<environment-name>-<elasticsearch-domain> | `string` | n/a | yes |
| <a name="input_elasticsearch_version"></a> [elasticsearch\_version](#input\_elasticsearch\_version) | Version of Elasticsearch to deploy | `string` | `"7.10"` | no |
| <a name="input_encryption_at_rest"></a> [encryption\_at\_rest](#input\_encryption\_at\_rest) | Whether to encrypt the domain at rest | `bool` | `false` | no |
| <a name="input_environment-name"></a> [environment-name](#input\_environment-name) | The type of environment you're deploying to. | `string` | n/a | yes |
| <a name="input_index_pattern"></a> [index\_pattern](#input\_index\_pattern) | Pattern created in Kibana, policy will apply to matching new indices | `string` | `"test_data*"` | no |
| <a name="input_infrastructure-support"></a> [infrastructure-support](#input\_infrastructure-support) | The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>) | `string` | n/a | yes |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Total data nodes in the cluster, includes warm | `number` | `3` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Elasticsearch instance type for data nodes in the cluster | `string` | `"t3.medium.elasticsearch"` | no |
| <a name="input_is-production"></a> [is-production](#input\_is-production) | Whether the ElasticSearch cluster is for production use. | `string` | n/a | yes |
| <a name="input_log_publishing_application_cloudwatch_log_group_arn"></a> [log\_publishing\_application\_cloudwatch\_log\_group\_arn](#input\_log\_publishing\_application\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group to which log for ES\_APPLICATION\_LOGS needs to be published | `string` | `""` | no |
| <a name="input_log_publishing_application_enabled"></a> [log\_publishing\_application\_enabled](#input\_log\_publishing\_application\_enabled) | Specifies whether log publishing option for ES\_APPLICATION\_LOGS is enabled or not | `string` | `"false"` | no |
| <a name="input_log_publishing_index_cloudwatch_log_group_arn"></a> [log\_publishing\_index\_cloudwatch\_log\_group\_arn](#input\_log\_publishing\_index\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group to which log for INDEX\_SLOW\_LOGS needs to be published | `string` | `""` | no |
| <a name="input_log_publishing_index_enabled"></a> [log\_publishing\_index\_enabled](#input\_log\_publishing\_index\_enabled) | Specifies whether log publishing option for INDEX\_SLOW\_LOGS is enabled or not | `string` | `"false"` | no |
| <a name="input_log_publishing_search_cloudwatch_log_group_arn"></a> [log\_publishing\_search\_cloudwatch\_log\_group\_arn](#input\_log\_publishing\_search\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group to which log for SEARCH\_SLOW\_LOGS  needs to be published | `string` | `""` | no |
| <a name="input_log_publishing_search_enabled"></a> [log\_publishing\_search\_enabled](#input\_log\_publishing\_search\_enabled) | Specifies whether log publishing option for SEARCH\_SLOW\_LOGS is enabled or not | `string` | `"false"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace from which the module is requested | `string` | n/a | yes |
| <a name="input_node_to_node_encryption_enabled"></a> [node\_to\_node\_encryption\_enabled](#input\_node\_to\_node\_encryption\_enabled) | Whether to enable node-to-node encryption | `bool` | `false` | no |
| <a name="input_s3_manual_snapshot_repository"></a> [s3\_manual\_snapshot\_repository](#input\_s3\_manual\_snapshot\_repository) | ARN of S3 bucket to use for manual snapshot repository | `string` | `""` | no |
| <a name="input_snapshot_enabled"></a> [snapshot\_enabled](#input\_snapshot\_enabled) | Set to false to prevent the module from creating snapshot resources | `string` | `"true"` | no |
| <a name="input_team_name"></a> [team\_name](#input\_team\_name) | The name of your development team | `string` | n/a | yes |
| <a name="input_timestamp_field"></a> [timestamp\_field](#input\_timestamp\_field) | Field Kibana identifies as Time field, when creating the index pattern | `string` | `"last_updated"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the vpc (eg.: live-1) | `string` | n/a | yes |
| <a name="input_warm_count"></a> [warm\_count](#input\_warm\_count) | Number of warm data nodes in the cluster | `number` | `2` | no |
| <a name="input_warm_enabled"></a> [warm\_enabled](#input\_warm\_enabled) | Whether to enable warm storage | `bool` | `false` | no |
| <a name="input_warm_transition"></a> [warm\_transition](#input\_warm\_transition) | Time until transition to warm storage | `string` | `"7d"` | no |
| <a name="input_warm_type"></a> [warm\_type](#input\_warm\_type) | Elasticsearch instance type for warm data nodes in the cluster | `string` | `"ultrawarm1.medium.elasticsearch"` | no |
| <a name="input_zone_awareness_enabled"></a> [zone\_awareness\_enabled](#input\_zone\_awareness\_enabled) | Enable zone awareness for Elasticsearch cluster | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_es_proxy_url"></a> [aws\_es\_proxy\_url](#output\_aws\_es\_proxy\_url) | URL for aws-es-proxy service |
| <a name="output_ism_policy"></a> [ism\_policy](#output\_ism\_policy) | paste this in Kibana, waiting for https://github.com/hashicorp/terraform-provider-aws/issues/25527 |
| <a name="output_snapshot_role_arn"></a> [snapshot\_role\_arn](#output\_snapshot\_role\_arn) | Snapshot role ARN |

<!-- END_TF_DOCS -->

### Tags

Some of the inputs are tags. All infrastructure resources need to be tagged according to the [MOJ technical guidance](https://ministryofjustice.github.io/technical-guidance/standards/documenting-infrastructure-owners/#documenting-owners-of-infrastructure). The tags are stored as variables that you will need to fill out as part of your module.

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| application |  | string | - | yes |
| business-unit | Area of the MOJ responsible for the service | string | `mojdigital` | yes |
| environment-name |  | string | - | yes |
| infrastructure-support | The team responsible for managing the infrastructure. Should be of the form team-email | string | - | yes |
| is-production |  | string | `false` | yes |
| team_name |  | string | - | yes |


## Outputs

When you create an AWS Elasticsearch cluster using this module, it will deploy a HTTP Proxy `aws-es-proxy` using the [aws-es-proxy repo](https://github.com/abutaha/aws-es-proxy) and a Service `aws-es-proxy-service`  You can use this service `aws-es-proxy-service` to access the elasticsearch from your application.

## Accessing the Elasticsearch

You can access the Elasticsearch from your application by doing `http://aws-es-proxy-service:9200` and access kibana by doing `http://aws-es-proxy-service:9200/_plugin/kibana/app/kibana`

### Accessing from your local machine

When you create an Elasticsearch using this module, it is created inside a
virtual private cloud (VPC), which will only accept network connections from
within the kubernetes cluster.  So, trying to connect to the Elasticsearch from
your local machine will not work.

```
+--------------+                   \ /                        +--------------+
| Your machine | -------------------X-----------------------> | Elasticsearch |
+--------------+                   / \                        +--------------+
```
You can use the service `aws-es-proxy-service` and setup a port-forward on your namespace to forward traffic from a port on your local machine.

```
kubectl \
  -n [your namespace] \
  port-forward \
  svc/aws-es-proxy-service 9200:9200
```

You need to leave this running as long as you are accessing the elasticsearch.

So, the connection from your machine to the Elasticsearch works like this:

```
+--------------+             +---------------------+          +--------------+
| Your machine |------------>| Proxy - Port forward  |--------->| Elasticsearch |
+--------------+             +---------------------+          +--------------+
```
You can access the Elasticsearch from your local machine by doing `http://localhost:9200` and access kibana by doing `http://localhost:9200/_plugin/kibana/app/kibana`

### Creating a public IP endpoint

You can create an ingress resource in your namespace, fronting the `aws-es-proxy-service` SVC; see [the user guide](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/deploying-an-app/helloworld-app-deploy.html#ingress-yaml) for details.
The HTTP endpoint is not authenticated by default, also check [the guide](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/deploying-an-app/helloworld-app-deploy.html#add-http-basic-authentication) for how to add HTTP Basic Authentication.
