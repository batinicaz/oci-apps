data "ct_config" "ignition" {
  content = templatefile("${path.module}/../os-config/butane.yaml", {
    TAILSCALE_AUTH_KEY              = tailscale_tailnet_key.this.key
    VAULT_SECRET_ID_CLIENT_ID       = oci_vault_secret.bootstrap["infisical-client-id"].id
    VAULT_SECRET_ID_CLIENT_SECRET   = oci_vault_secret.bootstrap["infisical-client-secret"].id
    VAULT_SECRET_ID_RESTIC_PASSWORD = oci_vault_secret.bootstrap["restic-password"].id
    BUCKET_NAME                     = oci_objectstorage_bucket.this.name
    OCI_REGION                      = var.oci_region
    OCI_NAMESPACE                   = data.oci_objectstorage_namespace.terraform.namespace
    FRESHRSS_HOST                   = local.services["freshrss"].fqdn
    FULLTEXTRSS_HOST                = local.services["fulltextrss"].fqdn
    PLANKA_HOST                     = local.services["planka"].fqdn
    NITTER_HOST                     = local.services["nitter"].fqdn
    REDLIB_HOST                     = local.services["redlib"].fqdn
  })
  strict       = true
  pretty_print = false
  files_dir    = "${path.module}/.."
}
