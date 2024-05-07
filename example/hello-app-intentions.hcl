# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

Kind = "service-intentions"
Name = "hello-app"
Sources = [
  {
    Name   = "*"
    Action = "allow"
  }
]
