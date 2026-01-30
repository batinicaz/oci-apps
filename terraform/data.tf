data "cloudflare_ip_ranges" "current" {}

data "cloudflare_zone" "selected" {
  zone_id = var.zone_id
}

data "oci_core_images" "fcos" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  sort_by        = "TIMECREATED"
  sort_order     = "DESC"

  filter {
    name   = "display_name"
    values = ["Fedora CoreOS*"]
    regex  = true
  }

  filter {
    name   = "state"
    values = ["AVAILABLE"]
  }
}

data "oci_identity_compartment" "terraform" {
  id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
}

data "oci_objectstorage_namespace" "terraform" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
}

data "terraform_remote_state" "oci_core" {
  backend = "s3"
  config = {
    bucket                      = "terraform-state"
    key                         = "oci-core/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    endpoints = {
      s3 = var.remote_state_endpoint
    }
  }
}
