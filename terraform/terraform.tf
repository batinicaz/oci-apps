terraform {
  required_version = "~> 1.10"

  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "oci-apps/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = "~> 0.14"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.25"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "oci" {
  fingerprint  = var.oci_fingerprint
  private_key  = var.oci_private_key
  region       = var.oci_region
  tenancy_ocid = var.oci_tenancy_id
  user_ocid    = var.oci_user_id

  ignore_defined_tags = [
    "Oracle-Tags.CreatedBy",
    "Oracle-Tags.CreatedOn",
  ]
}
