# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

client_addr = "{{ GetPrivateIP }}" # the private IP of the EC2 instance
bind_addr   = "{{ GetPrivateIP }}" # the private IP of the EC2 instance

acl {
  enabled                  = true
  default_policy           = "deny"
  enable_token_persistence = true

  tokens {
    initial_management = "<ROOT TOKEN>"
    agent              = "<AGENT TOKEN>"
  }
}

tls {
  defaults {
    verify_outgoing = true
    ca_file         = "<PWD>/secrets/ca.pem"
    cert_file       = "<PWD>/secrets/consul/dc1-server-consul-0.pem"
    key_file        = "<PWD>/secrets/consul/dc1-server-consul-0-key.pem"
  }

  grpc {
    verify_incoming = false
  }
}

ports {
  http     = -1 # disable
  https    = 8501
  grpc     = 8502 # need to leave enabled because this is used by xDS as well
  grpc_tls = 8503
}

connect {
  enabled = true
}
