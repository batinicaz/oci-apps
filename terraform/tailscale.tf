resource "null_resource" "regenerate_key" {
  // Can not reference instance directly as that would be a cyclic dependency so track properties that will trigger a new instance
  triggers = {
    availability_domain = var.availability_domain
    boot_volume_size    = var.boot_volume_size
    bucket              = oci_objectstorage_bucket.this.name
    compartment_id      = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
    image_id            = data.oci_core_images.fcos.images[0].id
    instance_ocpus      = var.instance_ocpus
    instance_ram        = var.instance_ram
    shape               = var.instance_shape
    subnet_id           = data.terraform_remote_state.oci_core.outputs.core_vcn_subnets["private"]
    // Force key regeneration when any ignition config input changes
    ignition_inputs = sha256(jsonencode({
      vault_client_id       = oci_vault_secret.bootstrap["infisical-client-id"].id
      vault_client_secret   = oci_vault_secret.bootstrap["infisical-client-secret"].id
      vault_restic_password = oci_vault_secret.bootstrap["restic-password"].id
      bucket                = oci_objectstorage_bucket.this.name
      region                = var.oci_region
      namespace             = data.oci_objectstorage_namespace.terraform.namespace
      services              = var.services
    }))
    // Force key regeneration when bootstrap config files change (baked into ignition)
    ignition_config_hash = sha256(join("", [
      file("${path.module}/../os-config/butane.yaml"),
      file("${path.module}/../os-config/scripts/first-boot.sh"),
      file("${path.module}/../os-config/scripts/fetch-config.sh"),
      file("${path.module}/../os-config/scripts/fetch-bootstrap-secrets.sh"),
      file("${path.module}/../os-config/scripts/gitops-sync.sh"),
      file("${path.module}/../os-config/systemd/first-boot.service"),
      file("${path.module}/../os-config/systemd/tailscaled.service"),
      file("${path.module}/../os-config/systemd/fetch-config.service"),
      file("${path.module}/../os-config/systemd/fetch-bootstrap-secrets.service"),
      file("${path.module}/../os-config/scripts/languagetool-ngrams.sh"),
    ]))
    // Force key regeneration when bucket bootstrap config changes (fetched at boot)
    bootstrap_config_hash = local.bootstrap_config_hash
  }

  depends_on = [oci_objectstorage_object.bootstrap_config]
}

resource "tailscale_tailnet_key" "this" {
  ephemeral     = false
  expiry        = 600
  preauthorized = true
  reusable      = false
  tags          = ["tag:oci"]

  lifecycle {
    replace_triggered_by = [null_resource.regenerate_key]
  }
}
