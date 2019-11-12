# cloud-platform-terraform-elasticsearch
Terraform module to add a AWS Elasticsearch and Kibana resource in the Cloud Platform
# cloud-platform-terraform-s3-bucket module

[![Releases](https://img.shields.io/github/release/ministryofjustice/cloud-platform-terraform-elasticsearch/all.svg?style=flat-square)](https://github.com/ministryofjustice/cloud-platform-terraform-elasticsearch/releases)

Terraform module that will create an AWS Elasticsearch cluster within a VPC and a relevant IAM role that will have access to the Elasticsearch.

The resources created will have a randomised name of the format `cloud-platform-7a5c4a2a7e2134a`. This ensures that the resources created is globally unique.

## Usage

```hcl
module "example_team_es" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-elasticsearch?ref=1.0"
  cluster_name           = "${var.cluster_name}"
  cluster_state_bucket   = "${var.cluster_state_bucket}"
  application            = "exampleapp"
  business-unit          = "example-bu"
  environment-name       = "dev"
  infrastructure-support = "cloud-platform@digital.justice.gov.uk"
  is-production          = "false"
  team_name              = "example-repo"
  elasticsearch-domain   = "example-es"
  namespace              = "my-namespace"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cluster_name | The name of the kubernetes cluster (eg.: live-1) | string |  | yes |
| cluster_state_bucket | The name of the S3 bucket holding the terraform state for the cluster | string | | yes |
| elasticsearch-domain | The domain name of the Elasticsearch cluster to create. This will be appended with the namespace name and will look like `<team_name>-<environment-name>-<elasticsearch-domain>`  | string | | yes |
| namespace | Namespace which will access the Elasticsearch cluster | string | | yes |
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

The outputs are stored as `kubernetes_secrets` resource in the namespace you specified.

| Name | Description |
|------|-------------|
| es_domain_arn | Arn for the AWS Elasticsearch domain |
| domain_endpoint | Domain-specific endpoint used to submit index, search, and data upload requests |
| kibana_endpoint | Domain-specific endpoint for Kibana without https scheme |
| iam_role_name | IAM role to access AWS Elasticsearch cluster from application |
| iam_role_arn | Arn of IAM role to use it as AssumeRole to access AWS Elasticsearch cluster from application |

## Accessing the Elasticsearch 

Examples of how to do signing HTTP requests to Elasticsearch from your application can be found in [AWS developer guide](https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-request-signing.html). Use the `iam_role_arn` (and then base64 decode) which you get from your kubernetes secret and you can AssumeRole to get credentials for Signing request from your application. 
You need to add the annotation `iam.amazonaws.com/role: <iam_role_name>` to the Pod which runs the application.

When you create an AWS Elasticsearch cluster using this module, it will deploy a HTTP Proxy `aws-es-proxy` using the [aws-es-proxy repo](https://github.com/abutaha/aws-es-proxy) and a Service `aws-es-proxy-service` to access the proxy from outside. You can exec into the Pod and use curl to access the Elasticsearch using the domain_endpoint.

### Access from outside the cluster

When you create an Elasticsearch using this module, it is created inside a
virtual private cloud (VPC), which will only accept network connections from
within the kubernetes cluster.  So, trying to connect to the Elasticsearch from
your local machine will not work.

```
+--------------+                   \ /                        +--------------+
| Your machine | -------------------X-----------------------> | Elasticsearch |
+--------------+                   / \                        +--------------+
```

If you need to access your elasticsearch from outside the cluster (e.g. from your
own development machine), you can use the `aws-es-proxy-service` and setup a port-forward on your namespace to forward traffic from a port on your local machine.

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
You can access the Elasticsearch from your local machine by doing `http://localhost:9200`
