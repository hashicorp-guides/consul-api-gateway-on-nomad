Kind      = "service-defaults"
Name      = "hello-app"
Protocol = "http"
UpstreamConfig = {
  Defaults = {
    Protocol = "http"
    PassiveHealthCheck = {
      EnforcingConsecutive5xx = 0
    }
  }
}
