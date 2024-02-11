## How to get this running

1. If Consul and Nomad are already running (or you want them to run for testing), skip the below steps.
    - Start Consul in dev mode `sudo consul agent -dev -ui -data-dir /tmp/consul -config-file=consul-agent-config.hcl`
    - Start Nomad in dev mode `sudo -E nomad agent -dev-connect -config=nomad-agent-config.hcl`. Will start both Nomad server and client.
2. Generate certs for Nomad and Consul. Sample certs generation and usage could be found here [Consul Certs](https://developer.hashicorp.com/consul/tutorials/security-operations/tls-encryption-openssl-secure) and [Nomad Certs](https://developer.hashicorp.com/nomad/tutorials/transport-security/security-enable-tls).
3. Compress the certs folder and upload to an artifact repository.
4. Edit the `artifact.source` URL in `api-gateway-docker.nomad.hcl` and `hello-app-golang-docker.nomad.hcl` to point to the artifact repository.
5. Upload the certs in Nomad and Consul nodes, update the corresponding paths in `tls` settings for `consul-agent-config.hcl` and `nomad-agent-config.hcl`.
6. Updqate the `consul` settings with proper cert path in `nomad-agent-config.hcl`.
7. Create appropriate [ACL Token](https://developer.hashicorp.com/consul/tutorials/security/access-control-setup-production) for services to be deployed i.e. Nomad servers, Nomad clients, Consul servers, Consul clients, Example Apps, etc.
   The corresponding policies could be found in the acl folder in this repo. Use the following commands to create the tokens and policies.
   ```
   consul acl bootstrap

   consul acl policy create -name "my-api-gateway" -rules @acl/my-api-gateway-policy.hcl -description "api gateway policy"
   consul acl token create -description "Token for my-api-gateway" -policy-name "my-api-gateway"

   consul acl policy create -name "hello-app-register" -rules @acl/hello-app-policy.hcl -description "Allow hello-app to register into the catalog"
   consul acl token create -description "Service token for hello-app" -policy-name "hello-app-register"

   consul acl policy create -name "nomad-agent" -description "Nomad Agent Policy" -rules @acl/nomad-agent-policy.hcl
   consul acl token create -description "Nomad Agent Token" -policy-name "nomad-agent"

   consul acl policy create -name "consul-agent" -description "Consul Agent Policy" -rules @acl/consul-agent-policy.hcl
   consul acl token create -description "d9acecc4-acd7-8bf7-2165-40c8c899ce7a agent token" -node-identity "d9acecc4-acd7-8bf7-2165-40c8c899ce7a:dc1" -policy-name "consul-agent"
   ```
8. Deployment of API-GW requires and image with both Consul and Envoy, build an image using the Dockerfile in this repo and push it to a registry of your choice.
   Update the `config.image` value in `api-gateway-docker.nomad.hcl` to point to the image.
9. Write proxy-defaults and service-defaults in Consul. (If you don't have configs defined for each service and proxy already).
    - Use files proxy-defaults.hcl and service-defaults.hcl in this repo.
    - `consul config write proxy-default.hcl`
    - `consul config write service-default.hcl `
10. Create Nomad variables for api-gateway and the echo-app, below are the sample commands.
   ```
   nomad var put nomad/jobs/consul/conf consul_token=<consul token for api-gw> consul_http_addr=<consul https url:consul https port> consul_grpc_addr=<consul https grpc url:consul grpc port>
   nomad var put nomad/jobs/golang/apps/echo consul_token=<consul token for echo-app>
   ```
11. Start API-GW, following instructions below.
    - Look at the api-gateway-docker.nomad.hcl file in this repo.
    - Edit the ports and Consul address appropriately.
    - Run `nomad run api-gateway-docker.nomad.hcl`
    - Check Nomad UI, you should see the job running.
    - Check Consul UI, you should see the API-GW registered.
12. Start hello-app, following instructions below.
    - Look at the hello-app-golang-docker.nomad.hcl file in this repo.
    - Edit the ports and Consul address appropriately.
    - Run `nomad run hello-app-golang-docker.nomad.hcl`
    - Check Nomad UI, you should see the job running.
    - Check Consul UI, you should see the example-app registered.
13. Add intentions to allow traffic from API-GW to example-app.
    - Use file rest-api-intentions.hcl in this repo.
    - Run `consul config write rest-api-intentions.hcl`
14. Register listener for API-GW.
    - Use file gateway-listeners.hcl in this repo.
    - Run `consul config write gateway-listeners.hcl`
15. Register http routes for API-GW. So, that Envoy knows how and where to write the traffic.
    - Use file my-http-route.hcl in this repo.
    - Run `consul config write my-http-route.hcl`.
16. Test the API-GW.
    - Run `curl -v http://<api-gw-address>:<api-gw-port>/hello`
    - You should see the response from hello-app.
17. For additional debugging, you could dive into Envoy configs through envoy admin url, nomad job logs and consul catalog service definition.

https://developer.hashicorp.com/nomad/docs/configuration/consul

Notes:

consul config write proxy-default.hcl
consul config write service-default.hcl
consul config write hello-app-intentions.hcl
consul config write gateway-listeners.hcl
consul config write my-http-route.hcl


consul certs - https://developer.hashicorp.com/consul/tutorials/security-operations/tls-encryption-openssl-secure, https://developer.hashicorp.com/consul/commands/tls/cert
nomad certs - https://developer.hashicorp.com/nomad/docs/commands/tls/cert-create
nomad volume mount - https://developer.hashicorp.com/nomad/docs/job-specification/volume


```
consul tls ca create
consul tls cert create -server -node="ip-172.31.94.134.ec2.internal" -dc="dc1" -additional-ipaddress=172.31.94.134 -additional-dnsname="ec2-44-201-210-58.compute-1.amazonaws.com" -additional-dnsname="ip-172.31.94.134.ec2.internal"

nomad tls ca create
nomad tls cert create -client -additional-ipaddress=172.31.94.134 -additional-dnsname="ec2-44-201-210-58.compute-1.amazonaws.com" -additional-dnsname="ip-172.31.94.134.ec2.internal" -additional-dnsname="server.global.nomad"

export CONSUL_HTTP_ADDR=https://172.31.94.134:8501
export CONSUL_CACERT=~/hashicorp-consul-gateway-on-nomad/certs/consul/consul-agent-ca.pem
export CONSUL_CLIENT_CERT=~/hashicorp-consul-gateway-on-nomad/certs/consul/dc1-server-consul-0.pem
export CONSUL_CLIENT_KEY=~/hashicorp-consul-gateway-on-nomad/certs/consul/dc1-server-consul-0-key.pem
export CONSUL_HTTP_TOKEN=403b5555-d06d-c1b8-a663-36e3975662d4

export NOMAD_ADDR=https://172.31.94.134:4646
export NOMAD_CACERT=~/hashicorp-consul-gateway-on-nomad/certs/nomad/nomad-agent-ca.pem
export NOMAD_CLIENT_CERT=~/hashicorp-consul-gateway-on-nomad/certs/nomad/global-client-nomad.pem
export NOMAD_CLIENT_KEY=~/hashicorp-consul-gateway-on-nomad/certs/nomad/global-client-nomad-key.pem
```


```
nomad var put nomad/jobs/consul/conf consul_token=172702c0-a023-d756-b91c-193dcf2659e5 consul_http_addr=https://172.31.94.134:8501 consul_grpc_addr=https://172.31.94.134:8502
nomad var put nomad/jobs/golang/apps/echo consul_token=55074cad-bca2-5bb2-43bf-69f34eeaab91
```