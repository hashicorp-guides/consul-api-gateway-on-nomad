ui = true
enable_script_checks = false
disable_remote_exec = true
client_addr = "127.0.0.1"
verify_incoming = false
tls {
  defaults {
    verify_incoming = true
    verify_outgoing = true
    ca_file = "~/consul-agent-ca.pem"
    cert_file = "~/server1.dc1.consul.crt"
    key_file = "~/server1.dc1.consul.key"
  }
  internal_rpc {
    verify_server_hostname = true
  }
}
ports {
  http = -1
  https = 8501
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