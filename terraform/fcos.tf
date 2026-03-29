locals {
  fcos = jsondecode(file("${path.module}/../fcos-version.json"))
}

resource "terraform_data" "fcos_version" {
  input = local.fcos.version
}

resource "oci_objectstorage_bucket" "fcos" {
  count          = var.fcos_upload ? 1 : 0
  access_type    = "NoPublicAccess"
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  name           = "${var.name}-fcos-${local.fcos.version}"
  namespace      = data.oci_objectstorage_namespace.terraform.namespace
  storage_tier   = "Standard"
  versioning     = "Disabled"

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-fcos-${local.fcos.version}"
  })
}

resource "oci_objectstorage_object" "fcos" {
  count     = var.fcos_upload ? 1 : 0
  namespace = data.oci_objectstorage_namespace.terraform.namespace
  bucket    = oci_objectstorage_bucket.fcos[0].name
  object    = "fedora-coreos-${local.fcos.version}-oraclecloud.aarch64.qcow2"
  source    = var.fcos_image_path
}

resource "oci_core_image" "fcos" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name   = "Fedora CoreOS ${local.fcos.version}-oraclecloud aarch64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type       = "objectStorageTuple"
    namespace_name    = data.oci_objectstorage_namespace.terraform.namespace
    bucket_name       = "${var.name}-fcos-${local.fcos.version}"
    object_name       = "fedora-coreos-${local.fcos.version}-oraclecloud.aarch64.qcow2"
    source_image_type = "QCOW2"
    operating_system  = "Fedora"
  }

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "fcos-${local.fcos.version}"
  })

  timeouts {
    create = "2h"
  }

  lifecycle {
    # image_source_details is create-only and not returned by the OCI API, so it is never in state
    ignore_changes       = [image_source_details]
    replace_triggered_by = [terraform_data.fcos_version]
  }
}

resource "oci_core_compute_image_capability_schema" "fcos" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  image_id       = oci_core_image.fcos.id
  display_name   = oci_core_image.fcos.display_name

  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas_versions.fcos.compute_global_image_capability_schema_versions[0].name

  schema_data = {
    "Compute.AMD_SecureEncryptedVirtualization" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = true
    })
    "Compute.SecureBoot" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = true
    })
    "Storage.Iscsi.MultipathDeviceSupported" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = true
    })
  }
}

resource "oci_core_shape_management" "fcos" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  image_id       = oci_core_image.fcos.id
  shape_name     = var.instance_shape
}
