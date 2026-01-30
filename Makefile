SECRETS := infisical run --env=terraform-common -- \
	infisical run --env=terraform-oci-apps --

.PHONY: init plan apply destroy fmt validate console lock

terraform/.terraform:
	cd terraform && $(SECRETS) terraform init

init: terraform/.terraform

plan: terraform/.terraform
	cd terraform && $(SECRETS) terraform plan

apply: terraform/.terraform
	cd terraform && $(SECRETS) terraform apply

destroy: terraform/.terraform
	cd terraform && $(SECRETS) terraform destroy

fmt:
	terraform fmt -recursive terraform/

validate: terraform/.terraform
	cd terraform && $(SECRETS) terraform validate

console: terraform/.terraform
	cd terraform && $(SECRETS) terraform console

lock: terraform/.terraform
	cd terraform && terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
