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
