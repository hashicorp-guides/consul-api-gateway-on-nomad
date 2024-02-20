ui = true
enable_script_checks = false
disable_remote_exec = true
client_addr = "{{ GetPrivateIP }}" # the private IP of the EC2 instance
bind_addr = "{{ GetPrivateIP }}" # the private IP of the EC2 instance
tls {
  defaults {
    verify_outgoing = true
    ca_file = "certs/consul/consul-agent-ca.pem"
    cert_file = "certs/consul/dc1-server-consul-0.pem"
    key_file = "certs/consul/dc1-server-consul-0-key.pem"
  }
  grpc {
    verify_incoming = false
  }
}
ports {
  http = -1 # becomes -1 if https is enabled, else http requests will still work
  https = 8501
  grpc = 8502 # used by xDS as well.
  grpc_tls = 8503
}
connect {
  enabled = true
}
acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
}
