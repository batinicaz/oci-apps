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

resource "oci_objectstorage_object_lifecycle_policy" "delete_old_backups" {
  namespace = oci_objectstorage_bucket.this.namespace
  bucket    = oci_objectstorage_bucket.this.name

  rules {
    action      = "DELETE"
    is_enabled  = true
    name        = "delete-old-backups"
    target      = "objects"
    time_amount = 7
    time_unit   = "DAYS"

    object_name_filter {
      inclusion_prefixes = ["backups/"]
    }
  }

  rules {
    action      = "DELETE"
    is_enabled  = true
    name        = "delete-old-versions"
    target      = "previous-object-versions"
    time_amount = 3
    time_unit   = "DAYS"

    object_name_filter {
      inclusion_prefixes = ["backups/"]
    }
  }

  depends_on = [
    oci_identity_policy.storage_service
  ]
}
