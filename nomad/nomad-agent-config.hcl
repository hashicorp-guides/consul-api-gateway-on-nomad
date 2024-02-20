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
  # set as environment variable CONSUL_HTTP_ADDR
  # address = "<consul ip address>:8501" # private address of the EC2 instance running Consul
  # set as environment variable CONSUL_GRPC_ADDR
  # grpc_address = "<consul ip address>:8503"
  ssl       = true

  # these are certs that consul-nomad use to establish TLS/mTLS
  grpc_ca_file = "certs/consul/consul-agent-ca.pem"
  ca_file = "certs/consul/consul-agent-ca.pem"
  cert_file = "certs/consul/dc1-server-consul-0.pem"
  key_file = "certs/consul/dc1-server-consul-0-key.pem"

  service_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  task_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }
}

# Enable the server
server {
  enabled = true

  # should be 3 or 5 for production
  bootstrap_expect = 1
}

# Require TLS
tls {
  http = true
  rpc  = true

  # These are certs that Nomad uses to interact with Nomad over TLS/mTLS
  ca_file   = "certs/nomad/nomad-agent-ca.pem"
  cert_file = "certs/nomad/global-client-nomad.pem"
  key_file  = "certs/nomad/global-client-nomad-key.pem"

  verify_server_hostname = true
  verify_https_client    = true
}

acl {
  enabled = true
}
