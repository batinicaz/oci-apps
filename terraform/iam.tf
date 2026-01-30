resource "oci_identity_dynamic_group" "this" {
  compartment_id = var.oci_tenancy_id
  name           = var.name
  description    = "Dynamic group for ${var.name} instance"
  matching_rule  = "instance.id = '${oci_core_instance.this.id}'"

  defined_tags = merge(local.default_tags, {
    "terraform.name" = var.name
  })
}

resource "oci_identity_policy" "vault_read_secrets" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  name           = "${var.name}-vault-read"
  description    = "Allow ${var.name} to read bootstrap secrets from OCI Vault"

  statements = [
    <<-POLICY
      Allow dynamic-group ${oci_identity_dynamic_group.this.name} to read secret-bundles in compartment id
      ${data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id}
      where target.vault.id='${oci_kms_vault.this.id}'
    POLICY
  ]

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-vault-read"
  })
}

resource "oci_identity_policy" "storage_access" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  name           = "${var.name}-storage-access"
  description    = "Allow ${var.name} to manage objects in storage bucket"
  statements = [
    <<-POLICY
      Allow dynamic-group ${oci_identity_dynamic_group.this.name} to manage object-family in compartment id
      ${data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id}
      where target.bucket.name='${oci_objectstorage_bucket.this.name}'
    POLICY
    ,
    <<-POLICY
      Allow dynamic-group ${oci_identity_dynamic_group.this.name} to use keys in compartment id
      ${data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id}
      where target.key.id='${oci_kms_key.this.id}'
    POLICY
  ]

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-storage-access"
  })
}

resource "oci_identity_policy" "storage_service" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  description    = "Allow object storage service to use encryption and manage lifecycle"
  name           = "${var.name}-storage-service"

  statements = [
    <<-POLICY
      Allow service objectstorage-${var.oci_region}
      to use keys in compartment ${data.oci_identity_compartment.terraform.name}
      where target.key.id='${oci_kms_key.this.id}'
    POLICY
    ,
    <<-POLICY
      Allow service objectstorage-${var.oci_region}
      to manage object-family in compartment ${data.oci_identity_compartment.terraform.name}
      where target.bucket.name='${local.bucket_name}'
    POLICY
  ]

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-storage-service"
  })
}
