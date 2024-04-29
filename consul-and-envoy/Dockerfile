# This Dockerfile copies Consul from the official release Docker image into the
# Envoy proxy, and sets Consul as the default command

ARG CONSUL_IMAGE_NAME=hashicorp/consul
ARG CONSUL_IMAGE_VERSION=1.17.1
ARG ENVOY_IMAGE_VERSION=v1.27.2

FROM ${CONSUL_IMAGE_NAME}:${CONSUL_IMAGE_VERSION} as consul
FROM envoyproxy/envoy:${ENVOY_IMAGE_VERSION}

COPY --from=consul /bin/consul /bin/consul
CMD ["/bin/consul"]
