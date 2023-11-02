Kind = "http-route"
Name = "my-http-route"

// Rules define how requests will be routed
Rules = [
  // Send all requests to UI services with 10% going to the "experimental" UI
  {
    Matches = [
      {
        Path = {
          Match = "prefix"
          Value = "/"
        }
      }
    ]
    Services = [
      {
        Name = "ui"
        Weight = 90
      },
      {
        Name = "experimental-ui"
        Weight = 10
      }
    ]
  },
  // Send all requests that start with the path `/api` to the API service
  {
    Matches = [
      {
        Path = {
          Match = "prefix"
          Value = "/api"
        }
      }
    ]
    Services = [
      {
        Name = "api"
      }
    ]
  }
]

Parents = [
  {
    Kind = "api-gateway"
    Name = "my-gateway"
    SectionName = "my-http-listener"
  }
]
