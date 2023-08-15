help: ## Prints help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.DEFAULT_GOAL := help

include .envrc
export

traefik:  ## Deploy traefik as Loadbalancer
	# admin:admin
	# "force" to be idempotent
	@nomad var put -force nomad/jobs/traefik/traefik/server BASIC_AUTH=admin:$apr1$01Fs7ov9$6f0dMQ4c6tfjck4vhbIIh1
	@nomad run ./jobs/traefik.hcl
	@nomad acl policy apply -namespace default -job traefik -group traefik -task traefik traefik-policy ./policies/traefik.policy.hcl

hello:  ## Deploy a hello-world Docker container
	@nomad run ./jobs/hello.hcl

blueprint:  ## Setup a namespace for a developer with limited permissions
	@nomad namespace apply -description "Developer's playground" dev
	@nomad run ./jobs/blueprint.hcl
	@echo "Creating token for developer"
	@nomad acl policy apply -description "Developer's Policy" dev ./policies/dev.policy.hcl
	@nomad acl token create -name="Max Mustermann" -policy="dev"

anonymous:  ## Create anonymous full-access policy
	@echo "WARNING: Applying full-access for anonymous!"
	@nomad acl policy apply -description "Anonymous policy (full-access)" anonymous ./policies/anonymous.policy.hcl

status:  ## nomad status
	@nomad status -namespace '*'

ui:  ## open Nomad UI in the default browser
	@nomad ui -authenticate
