# if certs are required for TLS/mTLS
# best approach would be to mount a volume containing pre-generated certs
# and then reference the path in the task definition
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

    task "agent" {
      driver = "docker"

      env {
        CONSUL_HTTP_ADDR="http://172.31.60.118:8500" # private IP of EC2 instance
        CONSUL_GRPC_ADDR="http://172.31.60.118:8502" # used for xDS
        token = ""
      }

      config {
        image = "kkavish/consul-envoy:latest" # image containing consul and envoy
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