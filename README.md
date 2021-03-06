# cloud-platform-terraform-elasticsearch
Terraform module to add a AWS Elasticsearch and Kibana resource in the Cloud Platform

[![Releases](https://img.shields.io/github/release/ministryofjustice/cloud-platform-terraform-elasticsearch/all.svg?style=flat-square)](https://github.com/ministryofjustice/cloud-platform-terraform-elasticsearch/releases)

Terraform module that will create an AWS Elasticsearch cluster within a VPC and a relevant IAM role that will provide access to the Elasticsearch.

The resources created will have a randomised name of the format `cloud-platform-7a5c4a2a7e2134a`. This ensures that the resources created is globally unique.

## Usage

See [the example README](https://github.com/ministryofjustice/cloud-platform-terraform-elasticsearch/blob/main/example/README.md)
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cluster_name | The name of the kubernetes cluster (eg.: live-1) | string |  | yes |
| elasticsearch-domain | The domain name of the Elasticsearch cluster to create. This will be appended with the namespace name and will look like `<team_name>-<environment-name>-<elasticsearch-domain>`  | string | | yes |
| namespace | Namespace which will access the Elasticsearch cluster | string | | yes |
| elasticsearch_version | Version of Elasticsearch to deploy  | string | `7.1` | no |
| aws_es_proxy_service_name | Name to be used by aws-es-proxy service  | string | "aws-es-proxy-service" | no |
| aws-es-proxy-replica-count | Number of es proxy replicas  | string | `1` | no |
| s3_manual_snapshot_repository | ARN of S3 bucket to use for manual snapshot repository  | string | | no |
| encryption_at_rest | Whether to encrypt the domain at rest | string | false | no |
| irsa_enabled | This will enable to use IRSA instead of KIAM | bool | false | no |
| assume_enabled | This will enable to use KIAM instead of IRSA | bool | true | no |


### Tags

Some of the inputs are tags. All infrastructure resources need to be tagged according to the [MOJ techincal guidence](https://ministryofjustice.github.io/technical-guidance/standards/documenting-infrastructure-owners/#documenting-owners-of-infrastructure). The tags are stored as variables that you will need to fill out as part of your module.

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
