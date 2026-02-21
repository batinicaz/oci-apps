resource "oci_core_volume" "data" {
  compartment_id      = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  availability_domain = var.availability_domain
  display_name        = "${var.name}-data"
  size_in_gbs         = 150
  vpus_per_gb         = 10

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-data"
  })
}

resource "oci_core_volume_attachment" "data" {
  attachment_type                     = "paravirtualized"
  instance_id                         = oci_core_instance.this.id
  volume_id                           = oci_core_volume.data.id
  is_pv_encryption_in_transit_enabled = true
}
