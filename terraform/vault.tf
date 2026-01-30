resource "oci_kms_vault" "this" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name   = var.name
  vault_type     = "DEFAULT"

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-vault"
  })
}

resource "oci_kms_key" "vault" {
  compartment_id      = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name        = "${var.name}-vault-key"
  desired_state       = "ENABLED"
  management_endpoint = oci_kms_vault.this.management_endpoint
  protection_mode     = "SOFTWARE" // Always free

  key_shape {
    algorithm = "AES"
    length    = 32 // 32 bytes AKA 256 bit key
  }

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-vault-key"
  })
}

locals {
  bootstrap_secrets = {
    infisical-client-id     = var.infisical_client_id
    infisical-client-secret = var.infisical_client_secret
    restic-password         = var.restic_password
  }
}

resource "oci_vault_secret" "bootstrap" {
  for_each       = local.bootstrap_secrets
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  vault_id       = oci_kms_vault.this.id
  key_id         = oci_kms_key.vault.id
  secret_name    = "${var.name}-${each.key}"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(each.value)
  }

  defined_tags = merge(local.default_tags, {
    "terraform.name" = each.key
  })
}
