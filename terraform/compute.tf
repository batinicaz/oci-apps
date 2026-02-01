resource "oci_core_instance" "this" {
  availability_domain                 = var.availability_domain
  compartment_id                      = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name                        = var.name
  is_pv_encryption_in_transit_enabled = true
  shape                               = var.instance_shape

  create_vnic_details {
    assign_public_ip = false
    nsg_ids          = [oci_core_network_security_group.instance.id]
    subnet_id        = data.terraform_remote_state.oci_core.outputs.core_vcn_subnets["private"]
  }

  defined_tags = merge(local.default_tags, {
    "terraform.name" = var.name
  })

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  launch_options {
    network_type                        = "PARAVIRTUALIZED"
    is_pv_encryption_in_transit_enabled = true
  }

  metadata = {
    user_data = base64encode(data.ct_config.ignition.rendered)
  }

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_ram
  }

  source_details {
    source_id               = data.oci_core_images.fcos.images[0].id
    source_type             = "image"
    boot_volume_size_in_gbs = var.boot_volume_size
  }
}

resource "oci_core_network_security_group" "instance" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name   = "${var.name}-instance"
  vcn_id         = data.terraform_remote_state.oci_core.outputs.core_vcn_id

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-instance"
  })
}

resource "oci_core_network_security_group_security_rule" "instance_ingress_http" {
  description               = "Allow HTTP from LB"
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.instance.id
  protocol                  = "6"
  source                    = oci_core_network_security_group.lb.id
  source_type               = "NETWORK_SECURITY_GROUP"
  stateless                 = false

  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "instance_egress" {
  // checkov:skip=CKV2_OCI_2: False positive - egress rule
  description               = "Allow all egress"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  protocol                  = "all"
  network_security_group_id = oci_core_network_security_group.instance.id
  stateless                 = false
}
