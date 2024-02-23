Kind = "api-gateway"
Name = "my-api-gateway"

// Each listener configures a port which can be used to access the Consul cluster
Listeners = [
  {
    Port     = 8088
    Name     = "my-http-listener"
    Protocol = "http"
  }
]
