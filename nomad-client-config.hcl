log_level = "DEBUG"

plugin "raw_exec" {
  config {
    enabled = true
  }
}

consul {
  address = "127.0.0.1:8501"
  grpc_address = "127.0.0.1:8503"
  ssl       = true
  ca_file   = "~/consul-agent-ca.pem"
  grpc_ca_file = "~/consul-agent-ca.pem"
  cert_file = "~/server1.dc1.consul.crt"
  key_file  = "~/server1.dc1.consul.key"
  token = "token"
}

# Setup data dir
data_dir = "/tmp/client1"

# Enable the client
client {
  enabled = true

  # For demo assume you are talking to server1. For production,
  # this should be like "nomad.service.consul:4647" and a system
  # like Consul used for service discovery.
  server_join {
    retry_join = ["127.0.0.1:4647"]
  }
}

# Modify our port to avoid a collision with server1
ports {
  http = 5656
}

# Require TLS
tls {
  http = true
  rpc  = true

  ca_file   = "~/consul-agent-ca.pem"
  cert_file = "~/server1.dc1.consul.crt"
  key_file  = "~/server1.dc1.consul.key"

  verify_server_hostname = true
  verify_https_client    = true
}