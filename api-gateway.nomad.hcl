job "ingress" {

  type = "service"
  group "gateway" {

    task "agent" {
      driver = "raw_exec"
      
      env {
        CONSUL_HTTP_TOKEN="token"
        CONSUL_HTTP_ADDR="https://localhost:8501"
        CONSUL_CACERT="~/consul-agent-ca.pem"
        CONSUL_CLIENT_CERT="~/cli.client.dc1.consul.crt"
        CONSUL_CLIENT_KEY="~/cli.client.dc1.consul.key"
      }      

      config {
        command = "consul"
        args = [
          "connect",
          "envoy",
          "-gateway", "api",
          "-register",
          "-service", "my-api-gateway",
	      "-ignore-envoy-compatibility",
        ]
      }
    }
  }
}
