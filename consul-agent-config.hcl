ui = true
enable_script_checks = false
disable_remote_exec = true
client_addr = "{{ GetPrivateIP }}" # the private IP of the EC2 instance
bind_addr = "{{ GetPrivateIP }}" # the private IP of the EC2 instance
tls {
  defaults {
    verify_incoming = true
    verify_outgoing = true
    verify_server_hostname = true
    ca_file = "<path to consul CA cert>"
    cert_file = "<path to consul agent cert>"
    key_file = "<path to consul agent key>"
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

  tokens = {
    // consul agent token
    agent = "<consul agent token>"
  }
}