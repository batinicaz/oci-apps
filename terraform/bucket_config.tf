data "oci_core_subnet" "public" {
  subnet_id = data.terraform_remote_state.oci_core.outputs.core_vcn_subnets["public"]
}

locals {
  bootstrap_systemd_units = [
    "first-boot.service",
    "tailscaled.service",
    "tailscale-auth.service",
    "fetch-bootstrap-secrets.service",
    "fetch-config.service"
  ]

  config_directories = {
    quadlets         = "*.{container,network}"
    infisical-config = "**/*"
  }

  bootstrap_config_files = merge(
    merge([
      for dir, pattern in local.config_directories : {
        for f in fileset("${path.module}/../os-config/${dir}", pattern) :
        "config/${dir}/${f}" => "${path.module}/../os-config/${dir}/${f}"
        if !can(regex("^\\.", f))
      }
    ]...),
    {
      for f in fileset("${path.module}/../os-config/systemd", "*") :
      "config/systemd/${f}" => "${path.module}/../os-config/systemd/${f}"
      if !contains(local.bootstrap_systemd_units, f) && !can(regex("^\\.", f))
    }
  )

  templated_config_files = {
    "config/autorestic-config/autorestic.yml" = templatefile(
      "${path.module}/../os-config/autorestic-config/autorestic.yml",
      {
        BUCKET_NAME = oci_objectstorage_bucket.this.name
      }
    )
    "config/traefik-config/traefik.yml" = templatefile(
      "${path.module}/../os-config/traefik-config/traefik.yml.tftpl",
      {
        LB_SUBNET_CIDR = data.oci_core_subnet.public.cidr_block
      }
    )
    "config/traefik-config/dynamic/services.yml" = templatefile(
      "${path.module}/../os-config/traefik-config/dynamic/services.yml.tftpl",
      {
        FRESHRSS_HOST    = local.services["freshrss"].fqdn
        FULLTEXTRSS_HOST = local.services["fulltextrss"].fqdn
        PLANKA_HOST      = local.services["planka"].fqdn
        NITTER_HOST      = local.services["nitter"].fqdn
        REDLIB_HOST      = local.services["redlib"].fqdn
      }
    )
  }

  bootstrap_config_hash = sha256(jsonencode(merge(
    { for k, v in local.bootstrap_config_files : k => filesha256(v) },
    { for k, v in local.templated_config_files : k => sha256(v) }
  )))
}

resource "oci_objectstorage_object" "bootstrap_config" {
  for_each = local.bootstrap_config_files

  namespace    = data.oci_objectstorage_namespace.terraform.namespace
  bucket       = oci_objectstorage_bucket.this.name
  object       = each.key
  content      = file(each.value)
  content_type = "text/plain"
}

resource "oci_objectstorage_object" "templated_config" {
  for_each = local.templated_config_files

  namespace    = data.oci_objectstorage_namespace.terraform.namespace
  bucket       = oci_objectstorage_bucket.this.name
  object       = each.key
  content      = each.value
  content_type = "text/plain"
}
