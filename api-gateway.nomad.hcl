# default to the local image, but can be overriden by the user.
# use `nomad job run -var="consul_envoy_image=<image_name>:<tag_name>" api-gateway.nomad.hcl` while running the job, to override the default image.
variable "consul_envoy_image" {
  description = "The Consul Envoy image to use"
  type        = string
  default     = "consul-envoy:local"
}

variable "namespace" {
  description = "The Nomad namespace to use, which will bind to a specific Consul role"
  type        = string
  default     = "ingress"
}

job "ingress" {

  namespace = var.namespace

  group "gateway" {

    network {
      mode = "bridge"
      port "http" {
        static = 8088
        to     = 8088
      }
    }

    consul {
      # If the Consul token needs to be for a specific Consul namespace, you'll
      # need to set the namespace here

      # namespace = "foo"
    }

    task "api" {
      driver = "docker"

      config {
        image = var.consul_envoy_image # image containing consul and envoy
        args = [
          "consul",
          "connect", "envoy",
          "-gateway", "api",
          "-register",
          "-deregister-after-critical", "10s",
          "-service", "my-api-gateway",
          "-admin-bind", "0.0.0.0:19000",
          "-ignore-envoy-compatibility",
          # "-namespace", "foo", For Consul Enterprise only
          "--",
          "--log-level", "debug",
        ]
      }

      env {
        # these addresses need to match the specific Nomad node the allocation
        # is placed on, so it uses interpolation of the node attributes. The
        # CONSUL_HTTP_TOKEN variable will be set as a result of having template
        # blocks with Consul enabled.
        CONSUL_HTTP_ADDR = "https://${attr.unique.network.ip-address}:8501"
        CONSUL_GRPC_ADDR = "${attr.unique.network.ip-address}:8502" # xDS port (non-TLS)

        # these file paths are created by template blocks
        CONSUL_CLIENT_KEY  = "secrets/certs/consul_client_key.pem"
        CONSUL_CLIENT_CERT = "secrets/certs/consul_client.pem"
        CONSUL_CACERT      = "secrets/certs/consul_ca.pem"
      }

      template {
        destination = "secrets/certs/consul_ca.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/ingress/gateway/api" -}}
{{ .consul_cacert }}
{{- end -}}
EOF
      }

      template {
        destination = "secrets/certs/consul_client.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/ingress/gateway/api" -}}
{{ .consul_client_cert }}
{{- end -}}
EOF
      }

      template {
        destination = "secrets/certs/consul_client_key.pem"
        env         = false
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/ingress/gateway/api" -}}
{{ .consul_client_key }}
{{- end -}}
EOF
      }


    }
  }
}
