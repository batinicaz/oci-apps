locals {
  fcos              = jsondecode(file("${path.module}/../fcos-version.json"))
  fcos_build_url    = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/${local.fcos.version}/aarch64"
  fcos_meta         = local.fcos_needs_import ? jsondecode(data.http.fcos_meta[0].response_body).images.oraclecloud : null
  fcos_display_name = "Fedora CoreOS ${local.fcos.version}-oraclecloud aarch64"
  fcos_needs_import = length(data.oci_core_images.fcos_available.images) == 0
  fcos_object_name  = "fedora-coreos-${local.fcos.version}-oraclecloud.aarch64.qcow2"
}

data "oci_core_images" "fcos_available" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name   = local.fcos_display_name
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"

  filter {
    name   = "state"
    values = ["AVAILABLE"]
  }
}

resource "terraform_data" "fcos_version" {
  input = local.fcos.version
}

data "http" "fcos_meta" {
  count = local.fcos_needs_import ? 1 : 0
  url   = "${local.fcos_build_url}/meta.json"
}

resource "oci_objectstorage_bucket" "fcos" {
  count          = local.fcos_needs_import ? 1 : 0
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

resource "terraform_data" "fcos_upload" {
  count      = local.fcos_needs_import ? 1 : 0
  depends_on = [oci_objectstorage_bucket.fcos]

  input = {
    namespace   = data.oci_objectstorage_namespace.terraform.namespace
    bucket      = oci_objectstorage_bucket.fcos[0].name
    object_name = local.fcos_object_name
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/upload-fcos.sh"
    environment = {
      FCOS_VERSION             = local.fcos.version
      FCOS_BUILD_URL           = local.fcos_build_url
      FCOS_SHA256              = local.fcos_meta.sha256
      FCOS_UNCOMPRESSED_SHA256 = local.fcos_meta["uncompressed-sha256"]
      FCOS_OBJECT_NAME         = local.fcos_object_name
      OCI_NAMESPACE            = data.oci_objectstorage_namespace.terraform.namespace
      OCI_BUCKET               = oci_objectstorage_bucket.fcos[0].name
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = ". ${path.module}/scripts/oci-cli-env.sh && oci os object delete --namespace '${self.input.namespace}' --bucket-name '${self.input.bucket}' --name '${self.input.object_name}' --force 2>/dev/null || true"
  }
}

resource "oci_core_image" "fcos" {
  depends_on     = [terraform_data.fcos_upload]
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name   = local.fcos_display_name
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type       = "objectStorageTuple"
    namespace_name    = data.oci_objectstorage_namespace.terraform.namespace
    bucket_name       = "${var.name}-fcos-${local.fcos.version}"
    object_name       = local.fcos_object_name
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
