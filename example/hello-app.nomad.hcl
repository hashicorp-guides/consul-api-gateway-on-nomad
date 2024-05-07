# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

job "hello" {

  group "apps" {

    network {
      mode = "bridge"
      port "http" {
        to = "9090"
      }
    }

    service {
      name = "hello-app"
      port = "9090"

      connect {
        # runs a sidecar proxy
        sidecar_service {
          proxy {}
        }
      }
    }

    task "hello-app" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:latest"

        args = [
          "-listen",
          ":9090",
          "-text",
          "Hello World!",
        ]
      }
    }
  }
}
