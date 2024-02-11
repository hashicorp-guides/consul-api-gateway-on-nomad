# if certs are required for TLS/mTLS
# best approach would be to mount a volume containing pre-generated certs
# and then reference the path in the task definition
# CONSUL_API_GW_TOKEN = {{ .consul_token }}
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

      artifact {
        source = "<path to artifact with certs>"
        destination = "/certs"
      }

      template {
        destination = "config/consul.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/consul/conf" -}}
CONSUL_HTTP_TOKEN = {{ .consul_token }}
CONSUL_HTTP_ADDR = {{ .consul_http_addr }}
CONSUL_GRPC_ADDR = {{ .consul_grpc_addr }}
{{- end -}}
EOF
      }

      env {
        CONSUL_CLIENT_KEY="/certs/<path to consul client key>"
        CONSUL_CLIENT_CERT="/certs/<path to consul cert>"
        CONSUL_CACERT="/certs/<path to consul CA cert>"
      }

      config {
        image = "<docker hub repo OR local repo>/consul-envoy:latest" # image containing consul and envoy
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