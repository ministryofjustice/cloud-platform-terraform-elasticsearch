# aws-es-proxy
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
          image = "abutaha/aws-es-proxy:v1.0"
          name  = "aws-es-proxy"
          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            run_as_user                = 10001
          }
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