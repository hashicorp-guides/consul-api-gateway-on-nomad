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
{{- with nomadVar "nomad/jobs/golang/apps/echo" -}}
CONSUL_HTTP_TOKEN = {{ .consul_token }}
{{- end -}}
EOF
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