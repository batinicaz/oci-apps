SECRETS := infisical run --env=terraform-common -- \
	infisical run --env=terraform-<REPO_NAME> --

.PHONY: init plan apply destroy fmt validate console lock

.terraform:
	$(SECRETS) terraform init

init: .terraform

plan: .terraform
	$(SECRETS) terraform plan

apply: .terraform
	$(SECRETS) terraform apply

destroy: .terraform
	$(SECRETS) terraform destroy

fmt:
	terraform fmt -recursive

validate: .terraform
	$(SECRETS) terraform validate

console: .terraform
	$(SECRETS) terraform console

lock: .terraform
	terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
