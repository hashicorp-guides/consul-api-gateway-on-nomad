# default to the local image, but can be overriden by the user.
# use `nomad job run -var="consul_envoy_image=<image_name>:<tag_name>" api-gateway.nomad` while running the job, to override the default image.
variable "consul_envoy_image" {
  description = "The Consul Envoy image to use"
  type        = string
  default     = "consul-envoy:local"
}

job "ingress" {

  type = "service"

  group "gateway" {

    network {
      mode = "bridge"
      port "http" {
        static = 8088
        to = 8088
      }

      port "envoy-admin" {
        static = 19000
        to = 19000
      }
    }

    task "api" {
      driver = "docker"

      template {
        destination = "config/consul.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/ingress/gateway/api" -}}
CONSUL_HTTP_TOKEN = {{ .consul_token }}
CONSUL_HTTP_ADDR = {{ .consul_http_addr }}
CONSUL_GRPC_ADDR = {{ .consul_grpc_addr }}
{{- end -}}
EOF
      }

      template {
        destination = "local/certs/consul_ca.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/ingress/gateway/api" -}}
{{ .consul_cacert }}
{{- end -}}
EOF
      }

      template {
        destination = "local/certs/consul_client.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/ingress/gateway/api" -}}
{{ .consul_client_cert }}
{{- end -}}
EOF
      }

      template {
        destination = "local/certs/consul_client_key.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/ingress/gateway/api" -}}
{{ .consul_client_key }}
{{- end -}}
EOF
      }

      env {
        CONSUL_CLIENT_KEY = "local/certs/consul_client_key.pem"
        CONSUL_CLIENT_CERT = "local/certs/consul_client.pem"
        CONSUL_CACERT = "local/certs/consul_ca.pem"
      }

      config {
        image = var.consul_envoy_image # image containing consul and envoy
        args = [
          "consul",
          "connect", "envoy",
          "-gateway", "api",
          "-register",
          "-service", "my-api-gateway",
          "-admin-bind", "0.0.0.0:19000",
          "-ignore-envoy-compatibility",
          "--",
          "--log-level", "debug",
        ]
      }
    }
  }
}
