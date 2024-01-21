# Increase log verbosity
log_level = "DEBUG"

bind_addr = "172.31.60.118" # private address of the EC2 instance running Nomad

plugin "docker" {
  config {
    allow_privileged = true
    volumes {
      enabled = true
    }
    extra_labels = ["job_name", "job_id", "task_group_name", "task_name", "namespace", "node_name", "node_id"]
  }
}

plugin "raw_exec" {
  config {
    enabled=true
  }
}

consul {
  address = "172.31.60.118:8500" # private address of the EC2 instance running Consul
  grpc_address = "172.31.60.118:8502"
  ssl       = false

  # these are certs that consul-nomad use to establish TLS/mTLS
  ca_file   = ""
  grpc_ca_file = ""
  cert_file = ""
  key_file  = ""

  # input the nomad server token.
  token = ""
}

# Setup data dir
data_dir = "/home/ec2-user/nomad/server1" # data dir for the server

# Enable the server
server {
  enabled = true

  # Self-elect, should be 3 or 5 for production
  bootstrap_expect = 1
}

# Require TLS
tls {
  http = false
  rpc  = false

  # These are certs that Nomad used to interact with Nomad over TLS/mTLS
  ca_file   = ""
  cert_file = ""
  key_file  = ""

  verify_server_hostname = false
  verify_https_client    = false
}