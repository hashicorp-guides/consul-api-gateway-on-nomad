service "hello-app" {
  policy = "write"
}
service "hello-app-sidecar-proxy" {
  policy = "write"
}
service_prefix "" {
  policy = "write"
  intentions = "write"
}
node_prefix "" {
  policy = "read"
}
mesh = "write"
acl = "write"