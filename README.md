# Consul API Gateway on Nomad

## What is this?

An API Gateway is used for controlling access at entry and traffic management.
You can read more about it the [API gateways overview documentation][1].

This repository contains a working example of how to deploy an API Gateway using
Consul and Nomad. It includes the following:

1. Consul ACL roles, policies, and intentions for the API Gateway.
2. Nomad job specifications to deploy the API Gateway and an example upstream
   application.
3. A quick setup for trying it all out locally. This setup is similar to a
   production-grade deployment with mTLS enabled for both Consul and Nomad, but
   runs only on a single node.

This example uses Nomad's [Workload Identity][2] to authorize a Consul task to
bootstrap the Envoy gateway task and correctly register it with Consul. The API
Gateway is deployed in its own Nomad namespace. You'll add a Consul ACL role
that the Consul binding rule matches for that Nomad namespace. That Consul ACL
role grants the appropriate permissions to the API Gateway.

## Local quickstart setup

If you already have running Nomad and Consul clusters with Workload Identity as
described in the [Consul ACL with Nomad Workload Identities][3] tutorial, you can
skip this section.

<details><summary>quickstart</summary>

---

This quickstart guide assumes that you have both Consul and Nomad installed and
on your `PATH`.

1. **Set environment variables.**

If you have [`go-sockaddr`][4] installed, the rest of the setup will use it to
automatically get the correct IP address. If you do not, set it in your shell
session:

```
export NODE_IP=<< private IP address >>
```

2. **Create certificates, root tokens, and TLS configuration.**

```
cd quickstart
make
```

This will create TLS certificates for local use, as well as Nomad and Consul TLS
agent configurations.

3. **Start Consul.** In a new terminal window, navigate to the `quickstart`
   directory again, and start Consul in dev mode

```
consul agent -dev -config-file=./secrets/consul-agent.hcl
```

4. **Configure Consul CLI.** Go back to the previous terminal window, and set
   your environment to configure the Consul CLI to talk to the Consul
   agent. Note that this command is surrounded by `$(...)` to run in a subshell
   to export the environment correctly.

```
$(make consul-env)
```

You can see the environment variables this has created by running `env | grep
CONSUL`. It will include the `CONSUL_HTTP_ADDR`, the `CONSUL_HTTP_TOKEN`, and
variables for the certificate paths.

5. **Setup Initial Consul ACLs.**

Create a default Consul agent policy, and set the token for the Consul agent:

```
consul acl policy create -name "consul-agent" \
    -description "Consul Agent Policy" \
    -rules @acls/consul-agent-policy.hcl

consul acl token create -description="agent token" \
    -policy-name consul-agent \
    -secret=$(cat secrets/tokens/consul-agent)
```

Create a Consul ACL policy for the Nomad agent, and a token for the Nomad agent:

```
consul acl policy create -name "nomad-agent" \
    -description "Nomad Agent Policy" \
    -rules @acls/nomad-agent-policy.hcl

consul acl token create \
    -policy-name "nomad-agent" \
    -description "Nomad Agent Token" \
    -secret=$(cat secrets/tokens/nomad-agent)
```

Create default proxy configuration:

```
consul config write acls/proxy-default.hcl
```

6. **Start Nomad** In a new terminal window, navigate to the `quickstart`
   directory again, and start Nomad in dev mode

```
sudo nomad agent -dev -dev-connect -config ./secrets/nomad-agent.hcl
```

7. **Configure Nomad CLI.** Go back to the previous terminal window, and set
   your environment to configure the Nomad CLI to talk to the Nomad agent. Note
   that this command is surrounded by `$(...)` to run in a subshell to export
   the environment correctly.

```
$(make nomad-env)
```

8. **Bootstrap Nomad ACLs**

```
nomad acl bootstrap ./secrets/tokens/nomad-root
```

9. **Configure Nomad and Consul to use Workload Identity.** This will create a
   Consul auth method and binding rule that Nomad can use to get Consul tokens
   for Nomad workloads.

```
nomad setup consul -y \
    -jwks-url "$NOMAD_ADDR/.well-known/jwks.json" \
    -jwks-ca-file "$NOMAD_CACERT"
```

10. **Verify Nomad connectivity to Consul.** Checking the node status should
    show it has fingerprinted attributes for Consul

```
nomad node status -verbose -self | grep consul
```

---

</details>

If you've skipped this section because you already have a Nomad and Consul
cluster with Workload Identity configured, you should ensure your terminal is
configured with environment variables to connect to both the Consul and Nomad
APIs, and that you have a management token for both. Typically this should
include all the following variables:

```
CONSUL_CACERT
CONSUL_CLIENT_CERT
CONSUL_CLIENT_KEY
CONSUL_HTTP_ADDR
CONSUL_HTTP_TOKEN

NOMAD_CACERT
NOMAD_CLIENT_CERT
NOMAD_CLIENT_KEY
NOMAD_ADDR
NOMAD_TOKEN
```

Return to the root of the repository if you haven't already.

## Create required policies

Create a Nomad namespace:

```
nomad namespace apply \
    -description "namespace for Consul API Gateways" \
    ingress
```

Create a Consul policy for the API Gateway and a role with access to that
policy. Note that the name of the role must match the binding rule
`nomad-${value.nomad_namespace}-tasks` that you have previously set up for using
Nomad Workload Identity with Consul, when used with the `ingress` namespace you
just created.

```
consul acl policy create -name "api-gateways" \
    -description "api gateway policy" \
    -rules @acls/api-gateway.policy.hcl

consul acl role create \
       -name "nomad-ingress-tasks" \
       -description "role for Nomad API gateway workloads" \
       -policy-name "api-gateways"
```

## Upload certificates for API Gateway

The API Gateway job needs Consul mTLS certificates to communicate with
Consul. The job specification uses [Nomad Variables][5] to store these securely,
but you could also use Vault secrets. These variables need to be written to the
same namespace that the job will be deployed to.

```
nomad var put -namespace ingress \
    nomad/jobs/ingress/gateway/setup \
    consul_cacert=@$CONSUL_CACERT \
    consul_client_cert=@$CONSUL_CLIENT_CERT \
    consul_client_key=@$CONSUL_CLIENT_KEY
```

## Deploy API Gateway

Look at the `api-gateway.nomad.hcl` job specification file at the root of this
repository. Edit the main listener port `network.port.http.static` so that it's
listening on whichever port you'd like.

Run the Nomad job.

```
nomad job run ./api-gateway.nomad.hcl
```

If you have specific Docker images or Nomad namespace you'd like to use, pass
the `-var` option to the `nomad job run` command. For example:

```
nomad job run \
    -var="consul_image=hashicorp/consul:1.18.1" \
    -var="envoy_image=hashicorp/envoy:1.28.1" \
    -var="namespace=ingress" \
    ./api-gateway.nomad.hcl
```

Once the deployment is complete, you can check the Consul UI to see the API
Gateway registered.

## Run an example upstream

This section will run an example upstream application `hello` and configure
access to it from the API Gateway.

1. Add intentions to allow traffic from the API Gateway to `hello` by running
   `consul config write example/hello-app-intentions.hcl`

2. Register a listener for the API Gateway by running `consul config write
   example/gateway-listeners.hcl`

3. Register http routes for the API Gateway so that Envoy knows how and where to
   write the traffic by running `consul config write example/my-http-route.hcl`

4. Start the `hello` app by running `nomad run example/hello-app.nomad.hcl`

Once the deployment is complete, you can test the API Gateway.
- Run `nomad job status -namespace ingress ingress` to find the allocation for
  the API gateway.
- Run `nomad alloc -namespace ingress status :allocID` to find the address for that
  allocation.
- Run `curl -v http://<api-gateway-address>:<api-gateway-port>/hello`
- You should see the response from hello-app.

For additional debugging, you can dive into Envoy configs through the Envoy
admin url and `nomad alloc exec`, Nomad job logs and Consul catalog service
definition.


[1]: https://developer.hashicorp.com/consul/docs/connect/gateways/api-gateway
[2]: https://developer.hashicorp.com/nomad/docs/concepts/workload-identity
[3]: https://developer.hashicorp.com/nomad/tutorials/integrate-consul/consul-acl
[4]: https://github.com/hashicorp/go-sockaddr
[5]: https://developer.hashicorp.com/nomad/docs/concepts/variables
