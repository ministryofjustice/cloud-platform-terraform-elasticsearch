provider "elasticstack" {
  elasticsearch {}
}

resource "elasticstack_elasticsearch_watch" "duplicate_uid" {
  count = terraform.workspace == "live" ? 1 : 0
  watch_id = "duplicate_uid"
  active   = false

  trigger = jsonencode({
    "schedule" = {
      "interval" = "1m"
    }
  })

  input = jsonencode({
    "search" = {
      "request" = {
        "indices" = ["live_kubernetes_cluster-*"],
        "body" = {
          "size" : 0,
          "query" : {
            "bool" : {
              "filter" : [
                {
                  "range" : {
                    "@timestamp" : {
                      "from" : "{{period_end}}||-1m",
                      "to" : "{{period_end}}",
                      "include_lower" : true,
                      "include_upper" : true,
                      "format" : "epoch_millis",
                      "boost" : 1
                    }
                  }
                },
                {
                  "match_phrase" : {
                    "log" : {
                      "query" : "\"the same UID is used more than once\"",
                      "slop" : 0,
                      "zero_terms_query" : "NONE",
                      "boost" : 1
                    }
                  }
                }
              ],
              "adjust_pure_negative" : true,
              "boost" : 1
            }
          },
          "aggregations" : {}
        }
      }
    }
  })

  condition = jsonencode({
    "script" = {
      "source" = "return ctx.payload.hits.total > params.threshold",
      "params" = {
        "threshold" = 1
      }
    }
  })

  actions = jsonencode({
    "slack" = {
      "throttle_period" = "60m",
      "transform" = {
          "script" = {
            "source" = "return [ 'message' : Duplicate UID detected in Kubernetes cluster {{ctx.metadata.name}}. Please check the logs for more information.]"
          }
      }
      "slack" = {
        "message" = {
          "from" = "Elastic Cloud",
          "to" = ["@Jack Stockley"],
          "text" = "{{ctx.payload.message}}"
        }
      }
    }
  })

  metadata = jsonencode({
    "xpack" = {
      "type" = "json"
    }
  })
}

output "watch" {
  value = elasticstack_elasticsearch_watch.duplicate_uid.watch_id

  depends_on = [ ec_deployment_elasticsearch_keystore.slack ]
}

resource "ec_deployment_elasticsearch_keystore" "slack" {
  count = terraform.workspace == "live" ? 1 : 0
  deployment_id = kubernetes_deployment.aws-es-proxy.id
  setting_name  = "cloud-platform.kibana-alerts"
  value         = module.secret_manager.secret["slack_webhook_url"]

  depends_on = [ module.secret_manager ]
}