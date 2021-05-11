# Example AWS Elasticsearch configuration

The configuration in this directory creates an example AWS Elasticsearch cluster.

This example is designed to be used in the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments/) repository.

The output will be a service `aws-es-proxy-service` running in your namespace which you can use to access Elasticsearch from your application.

## Usage

In your namespace's path in the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments/) repository, create a directory called `resources` (if you have not created one already) and refer to the contents of [main.tf](main.tf) to define the module properties. Make sure to change placeholder values to what is appropriate and refer to the top-level README file in this repository for extra variables that you can use to further customise your resource.

Creating an elasticsearch cluster and accessing it is a 2 step process

1. Create the elasticsearch cluster using the `cloud-platform-terraform-elasticsearch` module. This module creates the Elasticsearch cluster, deploy the es_proxy, create the IAM role which grant permissions for aws_es_proxy and the pods of your namespace to access the ES cluster.

```hcl
module "example_team_es" {
  source                 = "github.com/ministryofjustice/cloud-platform-terraform-elasticsearch?ref=version"
  cluster_name           = var.cluster_name
  application            = "exampleapp"
  business-unit          = "example-bu"
  environment-name       = "dev"
  infrastructure-support = "cloud-platform@digital.justice.gov.uk"
  is-production          = "false"
  team_name              = "example-team"
  elasticsearch-domain   = "example-es"
  namespace              = "my-namespace"
  elasticsearch_version = "7.1"
}
```
2. Annotate the namespace with using `cloud-platform-terraform-ns-annotation` module so the IAM roles are permitted to be assumed within that namespace

```hcl
module "ns_annotation" {
  source              = "github.com/ministryofjustice/cloud-platform-terraform-ns-annotation?ref=version"
  ns_annotation_roles = [module.example_team_es.aws_iam_role_name]
  namespace           = var.namespace
}

```

NOTE: If you have already have IAM roles which different pods are annotated with, then the namespace annotation should include all the IAM roles joined by "," 

```hcl
module "ns_annotation" {
  source              = "github.com/ministryofjustice/cloud-platform-terraform-ns-annotation?ref=version"
  ns_annotation_roles = ["cloud-platform-7ight76587", module.example_team_es.aws_iam_role_name]
  namespace           = var.namespace
}

```

Commit your changes to a branch and raise a pull request. Once approved, you can merge and the changes will be applied. Shortly after, you should be able to access the service `aws-es-proxy-service` on kubernetes and acccess the resources.
