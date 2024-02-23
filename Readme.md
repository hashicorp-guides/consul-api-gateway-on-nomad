# Consul API Gateway on Nomad

## What is this?

An API Gateway is used for controlling access at entry and traffic management.
You can read more about it [here](https://developer.hashicorp.com/consul/docs/connect/gateways/api-gateway).

This repository contains a working example of how to deploy an API Gateway using Consul and Nomad. It has the following.
1. A Dockerfile to build an image with Consul and Envoy.
2. Certs to enable mTLS between Consul and Nomad.
3. Configs to start Consul and Nomad agents.
4. ACL files to define authorization to Consul services.
5. Nomad job files to deploy the API Gateway and an example app.

The example is on-par with production-grade deployment, with mTLS enabled for both Consul and Nomad, and ACLs/Intentions for services and agents.
We call it on-par because we have not deployed a multi-node setup, instead everything is running on a single node.

## How to get this running?

1. Navigate to the working-example directory (hashicorp-consul-gateway-on-nomad).
   `cd hashicorp-consul-gateway-on-nomad`
2. Generate certs for Nomad and Consul. Sample certs generation and usage could be found here [Consul Certs](https://developer.hashicorp.com/consul/tutorials/security/tls-encryption-secure) and [Nomad Certs](https://developer.hashicorp.com/nomad/tutorials/transport-security/security-enable-tls).
   Below are the commands to generate certificates in the `certs` folder. This example uses their path to configure Consul and Nomad.
   Remember, we have a single node deployment for this example, so the Consul server and the client are the same.
   ```bash
    cd certs/consul
    consul tls ca create
    consul tls cert create -server -dc dc1 -additional-ipaddress=<ip addr of the node> -additional-dnsname=<hostname of the node>
    cd ../nomad
    nomad tls ca create
    nomad tls cert create -server -region global -additional-ipaddress=<ip addr of the node> -additional-dnsname=<hostname of the node> -additional-dnsname="client.global.nomad"
   ```
3. Update the corresponding paths in `tls` settings for `consul/consul-agent-config.hcl` and `nomad/nomad-agent-config.hcl`. 
   These config files currently has the default path of `certs/` under this directory. So, if you have generated the certs in the same location, no need to update the paths.
4. Start Consul agent.
    - Start Consul in dev mode `consul agent -dev -ui -data-dir /tmp/consul -config-file=consul/consul-agent-config.hcl`
5. Create appropriate [ACL Tokens](https://developer.hashicorp.com/consul/tutorials/security/access-control-setup-production) for services to be deployed i.e. Nomad servers, Nomad clients, Consul servers, Consul clients, Example Apps, etc.
   The corresponding policies can be found in the acl folder in this repo. Use the following commands to create the tokens and policies.
   ```
   consul acl bootstrap
   
   export CONSUL_HTTP_TOKEN=<consul_bootstrap_token>
   export CONSUL_HTTP_ADDR=https://<ip addr of the node>:8501
   export CONSUL_CACERT=<path to consul CA>
   export CONSUL_CLIENT_CERT=<path to consul server cert>
   export CONSUL_CLIENT_KEY=<path to consul server key>

   consul acl policy create -name "my-api-gateway" -rules @consul/acl/my-api-gateway-policy.hcl -description "api gateway policy"
   consul acl token create -description "Token for my-api-gateway" -policy-name "my-api-gateway"

   consul acl policy create -name "hello-app-register" -rules @consul/acl/hello-app-policy.hcl -description "Allow hello-app to register into the catalog"
   consul acl token create -description "Service token for hello-app" -policy-name "hello-app-register"

   consul acl policy create -name "nomad-agent" -description "Nomad Agent Policy" -rules @consul/acl/nomad-agent-policy.hcl
   consul acl token create -description "Nomad Agent Token" -policy-name "nomad-agent"

   consul acl policy create -name "consul-agent" -description "Consul Agent Policy" -rules @consul/acl/consul-agent-policy.hcl
   consul acl token create -description "d9acecc4-acd7-8bf7-2165-40c8c899ce7a agent token" -node-identity "<node id of the agent>:<dc>" -policy-name "consul-agent"
   
   consul acl set-agent-token agent <acl token for consul agent create in the previous line>
   ```
6. Start Nomad agent.
    - Set up the environment variables before starting the Nomad agent.
   ```
   export CONSUL_HTTP_TOKEN=<Nomad agent token genererate in the previous step>
   export CONSUL_HTTP_ADDR=https://<ip addr of the consul node>:8501
   export CONSUL_CACERT=<path to server CA>
   export CONSUL_CLIENT_CERT=<path to Consul server cert>
   export CONSUL_CLIENT_KEY=<path to Consul server key>
   ```
    - Start Nomad server `sudo nomad agent -dev -config=nomad/nomad-agent-config.hcl`
7. Setup the environment variables for your Nomad CLI.
   ```
    export NOMAD_ADDR=https://<ip addr of the node>:4646
    export NOMAD_CACERT=<path to Nomad CA>
    export NOMAD_CLIENT_CERT=<path to Nomad client cert>
    export NOMAD_CLIENT_KEY=<path to Nomad client key>
   ```
8. Create appropriate [ACL Tokens](https://developer.hashicorp.com/nomad/tutorials/access-control/access-control-tokens)
    ```
    nomad acl bootstrap
    ```
    ```
    export NOMAD_TOKEN=<token generated in the line above>
    ```
    Note: this example generates and uses bootstrap token for simplicity, in production you should use a token with proper policies.
    The bootstrap token is used to create the policies and tokens for the services and Nomad clients.
9. Deployment of API Gateway requires and image with both Consul and Envoy, build an image using the Dockerfile in this repo and push it to a registry of your choice.
   ```
   cd /consul-and-envoy
   docker build -t consul-envoy:latest .
   ```
   Optionally, you can push the image to a remote registry.
   ```
   docker push consul-envoy:latest
   ```
10. Write proxy-defaults and service-defaults in Consul. (If you don't have configs defined for each service and proxy already).
    - Use files `proxy-defaults.hcl` and `service-defaults.hcl` in this repo.
    - `consul config write consul/defaults/proxy-default.hcl`
    - `consul config write consul/defaults/service-default.hcl`
11. Create [Nomad variables](https://developer.hashicorp.com/nomad/tutorials/variables/variables-create) for api-gateway and the echo-app.
    The variables have been put in `nomad/variables` folder in this repo. Update the values against the corresponding keys, post which you can run the below commands.
   ```
   nomad var put nomad/jobs/ingress/gateway/api @nomad/variables/gateway.json
   nomad var put nomad/jobs/golang/apps/echo @nomad/variables/hello-app.json
   ```
12. Start API Gateway, following instructions below.
    - Look at the api-gateway-docker.nomad.hcl file in this repo.
    - Edit the ports and Consul address appropriately.
    - Run `nomad run api-gateway-docker.nomad.hcl`
    - Running this would look for a `consul-envoy` docker image in the local registry.
    - To override this, run `nomad run -var="consul_envoy_image=<remote repo>/consul-envoy:latest" api-gateway-docker.nomad.hcl`
    - Check Nomad UI, you should see the job running.
    - Check Consul UI, you should see the API Gateway registered.
13. Add intentions to allow traffic from API Gateway to example-app.
    - Use file rest-api-intentions.hcl in this repo.
    - Run `consul config write consul/intentions/hello-app-intentions.hcl`
14. Register listener for API Gateway.
    - Use file gateway-listeners.hcl in this repo.
    - Run `consul config write consul/api-gateway-configs/gateway-listeners.hcl`
15. Register http routes for API Gateway so that Envoy knows how and where to write the traffic.
    - Use file my-http-route.hcl in this repo.
    - Run `consul config write consul/api-gateway-configs/my-http-route.hcl`.
16. Start hello-app following the instructions below..
    - Look at the hello-app-golang-docker.nomad.hcl file in this repo.
    - Edit the ports and Consul address appropriately.
    - Run `nomad run nomad/apps/hello-app-golang-docker.nomad.hcl`
    - Check Nomad UI, you should see the job running.
    - Check Consul UI, you should see the example-app registered.
17. Test the API Gateway.
    - Run `curl -v http://<api-gateway-address>:<api-gateway-port>/hello`
    - You should see the response from hello-app.
18. For additional debugging, you could dive into Envoy configs through envoy admin url, Nomad job logs and Consul catalog service definition.

# Additional Notes:
1. You can give a try to Nomad workload and service identities if you are not running strict mTLS between Consul and Nomad OR have a terminating gateway between them.
    - More on this [here](https://developer.hashicorp.com/nomad/tutorials/integrate-consul/consul-acl).
    - Then the jobs could run without the `consul_token` variable and the generation of the same could be skipped from the steps above.
