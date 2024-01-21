ui = true
enable_script_checks = false
disable_remote_exec = true
client_addr = "172.31.60.118" # the private IP of the EC2 instance
bind_addr = "172.31.60.118" # the private IP of the EC2 instance
verify_incoming = false
tls {
  defaults {
    verify_incoming = false
    verify_outgoing = false
    ca_file = ""
    cert_file = ""
    key_file = ""
  }
  internal_rpc {
    verify_server_hostname = false
  }
}
ports {
  http = 8500 # becomes -1 if https is enabled, else http requests will still work
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

  tokens = {
    // consul agent token
    agent = ""

    // default token
    default = ""
  }
}