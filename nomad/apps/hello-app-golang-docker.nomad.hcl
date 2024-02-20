job "golang" {

  group "apps" {

    network {
      mode = "bridge"
      port "http" {
        static = 9090
        to = "9090"
      }
    }

    service {
      name = "hello-app"
      port = "9090"
      provider = "consul"

      connect {
        # runs a sidecar proxy
        sidecar_service {
          proxy {}
        }
      }
    }
    
    task "echo" {
      driver = "docker"

      template {
        destination = "config/consul.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar -}}
CONSUL_HTTP_TOKEN = {{ .consul_token }}
{{- end -}}
EOF
      }

      template {
        destination = "local/certs/consul_ca.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/golang/apps/echo" -}}
{{ .consul_cacert }}
{{- end -}}
EOF
      }

      template {
        destination = "local/certs/consul_client.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/golang/apps/echo" -}}
{{ .consul_client_cert }}
{{- end -}}
EOF
      }

      template {
        destination = "local/certs/consul_client_key.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/golang/apps/echo" -}}
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
        image = "hashicorp/http-echo:latest"

        args = [
          "-listen",
          ":9090",
          "-text",
          "Hello World!",
        ]
      }
    }
  }
}
