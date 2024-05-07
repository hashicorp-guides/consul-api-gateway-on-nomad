# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

Kind = "http-route"
Name = "my-http-route"

// Rules define how requests will be routed
Rules = [
  {
    Matches = [
      {
        Path = {
          Match = "prefix"
          Value = "/hello"
        }
      }
    ]
    Services = [
      {
        Name = "hello-app"
      }
    ]
  }
]

Parents = [
  {
    Kind        = "api-gateway"
    Name        = "my-api-gateway"
    SectionName = "my-http-listener"
  }
]
