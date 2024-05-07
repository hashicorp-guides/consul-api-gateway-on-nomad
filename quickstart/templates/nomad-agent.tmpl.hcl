bind_addr = "{{ GetPrivateIP }}" # private address of the EC2 instance running Nomad

acl {
  enabled = true
}

# Require TLS
tls {
  http = true
  rpc  = true

  ca_file   = "<PWD>/secrets/ca.pem"
  cert_file = "<PWD>/secrets/nomad/global-server-nomad.pem"
  key_file  = "<PWD>/secrets/nomad/global-server-nomad-key.pem"

  verify_server_hostname = true
  verify_https_client    = false
}

# can't use sockaddr/template here like in bind_addr above
# sockaddr works well with Nomad registration, but doesn't work for envoy bootstrapping
consul {
  ssl = true

  service_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  task_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  # private address of the instance running Consul
  address      = "<NODE_IP>:8501"
  grpc_address = "<NODE_IP>:8503"

  # these are certs that consul-nomad use to establish TLS/mTLS
  grpc_ca_file = "<PWD>/secrets/ca.pem"
  ca_file      = "<PWD>/secrets/ca.pem"
  cert_file    = "<PWD>/secrets/consul/dc1-server-consul-0.pem"
  key_file     = "<PWD>/secrets/consul/dc1-server-consul-0-key.pem"

  # input the nomad server token.
  token = "<TOKEN>"
}
