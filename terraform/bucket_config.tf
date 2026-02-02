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
    infisical-config = "templates/*.tmpl"
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

  # Templates marked with custom=true have their own .tmpl file in os-config
  # Simple templates (custom=false) are generated from templates/env.tmpl.tftpl
  infisical_templates = {
    "freshrss.env"           = { path = "/freshrss", dest = "freshrss.env" }
    "planka.env"             = { path = "/planka", dest = "planka.env" }
    "planka-postgres.env"    = { path = "/planka/postgres", dest = "planka-postgres.env" }
    "nitter.env"             = { path = "/nitter", dest = "nitter.env" }
    "nitter-sessions"        = { path = "/nitter-sessions", dest = "nitter-sessions.jsonl", custom = true }
    "nitter-config.conf"     = { path = "/nitter", dest = "nitter.conf", custom = true }
    "redlib.env"             = { path = "/redlib", dest = "redlib.env" }
    "fulltextrss-config.php" = { path = "/fulltextrss", dest = "fulltextrss-config.php", custom = true }
    "ghcr-token"             = { path = "/", dest = "ghcr-token", custom = true }
    "healthcheck-urls.env"   = { path = "/healthchecks", dest = "healthcheck-urls.env" }
  }

  infisical_agent_config = yamlencode({
    infisical = {
      address = "https://eu.infisical.com"
    }
    auth = {
      type = "universal-auth"
      config = {
        client-id     = "/run/secrets/client-id"
        client-secret = "/run/secrets/client-secret"
      }
    }
    templates = [
      for name, config in local.infisical_templates : {
        source-path      = "/etc/infisical/templates/${name}.tmpl"
        destination-path = "/opt/secrets/${config.dest}"
        config = {
          polling-interval = "5m"
        }
      }
    ]
  })

  infisical_generated_templates = {
    for name, config in local.infisical_templates :
    "config/infisical-config/templates/${name}.tmpl" => templatefile(
      "${path.module}/templates/env.tmpl.tftpl",
      { SECRET_PATH = config.path }
    )
    if !lookup(config, "custom", false)
  }

  templated_config_files = merge(
    {
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
        local.service_hosts
      )
      "config/infisical-config/agent-config.yaml" = local.infisical_agent_config
    },
    local.infisical_generated_templates
  )

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
