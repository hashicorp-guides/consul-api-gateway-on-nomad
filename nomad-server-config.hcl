# Increase log verbosity
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
data_dir = "/tmp/server1"

# Enable the server
server {
  enabled = true

  # Self-elect, should be 3 or 5 for production
  bootstrap_expect = 1
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