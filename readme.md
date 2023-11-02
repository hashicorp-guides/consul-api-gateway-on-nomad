# Consul API Gateway on Nomad

## How to get this running

1. Generate certificates for use in Nomad and Consul, this demo uses the same certificate everywhere but if someone want to use different certificates either have them signed via the same CA or trust all the CAs in your servers/clients.
    - Generating consul certificates is documented [here](https://developer.hashicorp.com/consul/tutorials/security-operations/tls-encryption-openssl-secure)
    - Generating nomad certificates is documented [here](https://developer.hashicorp.com/nomad/tutorials/transport-security/security-enable-tls)
    - Copying x509 extensions from CA to certificates [here](https://security.stackexchange.com/questions/150078/missing-x509-extensions-with-an-openssl-generated-certificate)
    - Sample commands
     ```
       consul tls ca create

       consul tls cert create -server -dc dc1

       openssl req -new -newkey rsa:2048 -nodes -keyout server1.dc1.consul.key -out server1.dc1.consul.csr -subj '/CN=server.dc1.consul' -config san.cnf

       openssl x509 -req -in server1.dc1.consul.csr -CA consul-agent-ca.pem -CAkey consul-agent-ca-key.pem -CAcreateserial -out server1.dc1.consul.crt -days 3650 -copy_extensions=copyall

       openssl req -new -newkey rsa:2048 -nodes -keyout client.dc1.consul.key -out client.dc1.consul.csr -subj '/CN=client.dc1.consul' -config san.cnf

       openssl x509 -req -in client.dc1.consul.csr -CA consul-agent-ca.pem -CAkey consul-agent-ca-key.pem -out client.dc1.consul.crt -days 3650 -copy_extensions=copyall

       openssl req -new -newkey rsa:2048 -nodes -keyout cli.client.dc1.consul.key -out cli.client.dc1.consul.csr -subj '/CN=cli.client.dc1.consul' -config san.cnf

       openssl x509 -req -in cli.client.dc1.consul.csr -CA consul-agent-ca.pem -CAkey consul-agent-ca-key.pem -out cli.client.dc1.consul.crt -days 3650 -copy_extensions=copyall

       openssl pkcs12 -export -inkey cli.client.dc1.consul.key -in cli.client.dc1.consul.crt -out ui-chrome-cli.p12

       openssl pkcs12 -export -inkey cli.client.dc1.consul.key -in cli.client.dc1.consul.crt -out ui-chrome-cli.p12

       openssl pkcs12 -export -inkey cli.client.dc1.consul.key -in cli.client.dc1.consul.crt -out ui-chrome-cli.p12

       openssl pkcs12 -export -inkey cli.client.dc1.consul.key -in cli.client.dc1.consul.crt -out ui-chrome-cli.p12

       openssl pkcs12 -export -inkey cli.client.dc1.consul.key -in cli.client.dc1.consul.crt -out ui-chrome-cli.p12 -legacy
    ```
2. Export these environment variables, for convenience you can add them to your ~/.bash_profile file.
    ```
   export CONSUL_HTTP_TOKEN=
   export HOMEBREW_GITHUB_API_TOKEN=token
   export GITHUB_TOKEN=
   export CONSUL_HTTP_ADDR=https://localhost:8501
   export CONSUL_CACERT=~/consul-agent-ca.pem
   export CONSUL_CLIENT_CERT=~/cli.client.dc1.consul.crt
   export CONSUL_CLIENT_KEY=~/cli.client.dc1.consul.key
   export NOMAD_ADDR=https://localhost:4646
   export NOMAD_CACERT=~/consul-agent-ca.pem
   export NOMAD_CLIENT_CERT=~/cli.client.dc1.consul.crt
   export NOMAD_CLIENT_KEY=~/cli.client.dc1.consul.key
    ```
3. Start Consul `sudo consul agent -dev -ui -data-dir /tmp/consul -config-file=consul-agent-config.hcl`
4. Create Consul ACL tokens to manage Consul, access UI and use in Nomad server & client.
   - Create tokens for Consul [here](https://developer.hashicorp.com/consul/tutorials/security/access-control-setup-production)
   - Create tokens for Nomad to access Consul and Consul to allow it [here](https://developer.hashicorp.com/nomad/tutorials/integrate-consul/consul-service-mesh)
   - Commands
   ```
   consul acl bootstrap
   
   consul acl token create -description "<node-name> agent token" -node-identity "Consul Agent ID:dc1"
   
   consul acl policy create -name "nomad-server" -description "Nomad Server Policy" -rules @~/nomad-server-policy.hcl
   
   consul acl policy create -name "nomad-client" -description "Nomad Client Policy" -rules @~/nomad-client-policy.hcl
   
   consul acl token create -description "Token for <service-name>" -service-identity "my-api-gateway"
   ```
5. Start Nomad server `sudo nomad agent -dev -config=nomad-server-config.hcl`
6. Start Nomad client `sudo nomad agent -config nomad-client-config.hcl`
7. Check Consul UI, you should see Nomad client and server registered.
8. Check Nomad UI, you should see Nomad client and server registered.
9. Write inline-certificate to Consul `consul config write my-certificate.hcl`
10. Write gateway definition to Consul `consul config write gateways.hcl`
11. Run Nomad job to deploy gateway `sudo nomad run api-gateway.nomad.hcl`
12. Check Nomad UI, you should see gateway job running.
13. Check Consul UI, you should see gateway registered.

## Some Important Links

- [Debug Nomad Jobs](https://developer.hashicorp.com/nomad/docs/commands/alloc/exec)
- [Consul Block Nomad Config](https://developer.hashicorp.com/nomad/docs/configuration/consul)
- [Gateway Block for Nomad Job](https://developer.hashicorp.com/nomad/docs/job-specification/gateway), this supports all gateway types except api-gateway.
- [What is SAN?](https://www.digicert.com/faq/public-trust-and-certificates/what-is-a-multi-domain-san-certificate)


