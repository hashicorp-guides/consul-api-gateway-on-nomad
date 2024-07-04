# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


mesh = "read"

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "read"
}

# Change the API Gateway service name here if you are overriding 'var.api_gateway_name'
service "my-api-gateway" {
  policy = "write"
}
