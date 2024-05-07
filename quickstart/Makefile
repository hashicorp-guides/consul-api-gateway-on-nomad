SHELL = bash

NODE_IP ?= $(shell command -v sockaddr > /dev/null && sockaddr eval 'GetPrivateIP')
HOSTNAME ?= $(shell hostname)
PWD = $(shell pwd)

.PHONY: all
all: configs tokens certs

# Linux has easy facilities for this, but just in case we're on macOS instead
define uuid
$(shell printf "%04x%04x-%04x-%04x-%04x-%04x%04x%04x\n" \
	$$RANDOM $$RANDOM \
	$$RANDOM \
	$$(($$RANDOM & 0x0fff | 0x4000)) \
	$$(($$RANDOM & 0x3fff | 0x8000)) \
	$$RANDOM $$RANDOM $$RANDOM)
endef

# we'll keep all certs, tokens, and configuration here because we'll be writing
# templating ACL token secret IDs into the config files
secrets:
	mkdir -p secrets

.PHONY: clean
clean:
	rm -rf ./secrets

# ----------------------------------------
# CLI configuration, to be called in a subshell like $(make consul-env)

.PHONY: consul-env
consul-env:
	@echo "export CONSUL_HTTP_ADDR=https://${NODE_IP}:8501"
	@echo "export CONSUL_HTTP_TOKEN=$(shell cat secrets/tokens/consul-root)"
	@echo "export CONSUL_CACERT=$(PWD)/secrets/ca.pem"
	@echo "export CONSUL_CLIENT_CERT=$(PWD)/secrets/consul/dc1-server-consul-0.pem"
	@echo "export CONSUL_CLIENT_KEY=$(PWD)/secrets/consul/dc1-server-consul-0-key.pem"

.PHONY: nomad-env
nomad-env:
	@echo "export NOMAD_ADDR=https://${NODE_IP}:4646"
	@echo "export NOMAD_TOKEN=$(shell cat secrets/tokens/nomad-root)"
	@echo "export NOMAD_CACERT=$(PWD)/secrets/ca.pem"
	@echo "export NOMAD_CLIENT_CERT=$(PWD)/secrets/nomad/global-server-nomad.pem"
	@echo "export NOMAD_CLIENT_KEY=$(PWD)/secrets/nomad/global-server-nomad-key.pem"


# ----------------------------------------
# Agent configuration

.PHONY: configs
configs: secrets/consul-agent.hcl secrets/nomad-agent.hcl

secrets/consul-agent.hcl: templates/consul-agent.tmpl.hcl secrets/tokens/consul-root secrets/tokens/consul-agent
	sed -e 's~<PWD>~$(PWD)~g' \
		-e 's~<ROOT TOKEN>~$(shell cat secrets/tokens/consul-root)~g' \
		-e 's~<AGENT TOKEN>~$(shell cat secrets/tokens/consul-agent)~g' \
		templates/consul-agent.tmpl.hcl > secrets/consul-agent.hcl

secrets/nomad-agent.hcl: templates/nomad-agent.tmpl.hcl secrets/tokens/nomad-agent
	sed -e 's~<PWD>~$(PWD)~g' \
		-e 's~<TOKEN>~$(shell cat secrets/tokens/nomad-agent)~g' \
		-e 's~<NODE_IP>~$(NODE_IP)~g' \
		templates/nomad-agent.tmpl.hcl > secrets/nomad-agent.hcl

# ----------------------------------------
# ACL token generation

.PHONY: tokens
tokens: secrets/tokens/nomad-root secrets/tokens/nomad-agent secrets/tokens/consul-root secrets/tokens/consul-agent

secrets/tokens: secrets
	mkdir -p secrets/tokens

secrets/tokens/%: secrets/tokens
	echo "$(call uuid)" > $@

# ----------------------------------------
# mTLS certificate generation

.PHONY: certs
certs: secrets/consul/dc1-server-consul-0-key.pem secrets/nomad/global-server-nomad-0-key.pem

secrets/ca-key.pem: secrets/ca.pem
secrets/ca.pem: secrets
	cd secrets && consul tls ca create
	mv secrets/consul-agent-ca.pem secrets/ca.pem
	mv secrets/consul-agent-ca-key.pem secrets/ca-key.pem

secrets/consul/dc1-server-consul-0-key.pem: secrets/consul/dc1-server-consul-0.pem
secrets/consul/dc1-server-consul-0.pem: secrets/ca-key.pem
	mkdir -p secrets/consul
	cd secrets/consul && consul tls cert create -server -dc dc1 \
		-ca ../ca.pem \
		-key ../ca-key.pem \
		-additional-ipaddress="${NODE_IP}" \
		-additional-dnsname="${HOSTNAME}"

secrets/nomad/global-server-nomad-0-key.pem: secrets/nomad/global-server-nomad-0.pem
secrets/nomad/global-server-nomad-0.pem: secrets/ca-key.pem
	mkdir -p secrets/nomad
	cd secrets/nomad && nomad tls cert create -server -region global \
		-ca ../ca.pem \
		-key ../ca-key.pem \
		-additional-ipaddress="${NODE_IP}" \
		-additional-dnsname="${HOSTNAME}" \
		-additional-dnsname="client.global.nomad"
