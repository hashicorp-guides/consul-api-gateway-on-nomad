Kind = "service-intentions"
Name = "hello-app"
Sources = [
  {
    Name = "*"
    Permissions = [
      {
        Action = "allow"
        HTTP = {
          PathPrefix = "/"
          Methods    = ["GET", "PUT", "POST", "DELETE", "HEAD"]
        }
      }
    ]
  }
]
