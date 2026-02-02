resource "oci_kms_key" "this" {
  compartment_id      = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  desired_state       = "ENABLED"
  display_name        = var.name
  management_endpoint = data.terraform_remote_state.oci_core.outputs.kms_vault_endpoint
  protection_mode     = "SOFTWARE"

  defined_tags = merge(local.default_tags, {
    "terraform.name" = var.name
  })

  key_shape {
    algorithm = "AES"
    length    = "32"
  }
}

resource "oci_objectstorage_bucket" "this" {
  access_type           = "NoPublicAccess"
  compartment_id        = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  kms_key_id            = oci_kms_key.this.id
  name                  = local.bucket_name
  namespace             = data.oci_objectstorage_namespace.terraform.namespace
  object_events_enabled = true
  storage_tier          = "Standard"
  versioning            = "Enabled"

  defined_tags = merge(local.default_tags, {
    "terraform.name" = local.bucket_name
  })

  depends_on = [
    oci_identity_policy.storage_service
  ]
}

