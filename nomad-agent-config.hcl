# Increase log verbosity
log_level = "DEBUG"

bind_addr = "{{ GetPrivateIP }}" # private address of the EC2 instance running Nomad

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

# can't use sockaddr/template here like in bind_addr above
# sockaddr works well with Nomad registration, but doesn't work for envoy bootstrapping
consul {
  address = "172.31.94.134:8501" # private address of the EC2 instance running Consul
  grpc_address = "172.31.94.134:8502"
  ssl       = true

  # these are certs that consul-nomad use to establish TLS/mTLS
  grpc_ca_file = "<path to consul gRPC CA cert>"
  ca_file = "<path to consul CA cert>"
  cert_file = "<path to consul agent cert>"
  key_file = "<path to consul agent key>"

  # input the nomad server token.
  token = "<nomad token for corresponding access policy in Consul>"
}

# Setup data dir
data_dir = "/home/ec2-user/nomad/agent1" # data dir for the server

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

  # These are certs that Nomad uses to interact with Nomad over TLS/mTLS
  ca_file = "<path to Nomad CA cert>"
  cert_file = "<path to Nomad agent cert>"
  key_file = "<path to Nomad agent key>"

  verify_server_hostname = true
  verify_https_client    = true
}