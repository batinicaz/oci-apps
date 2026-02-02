# oci-apps

Self-hosted applications running on Oracle Cloud Infrastructure using Fedora CoreOS.

## Architecture

- **OS**: Fedora CoreOS with Ignition provisioning
- **Container Runtime**: Docker with Dockhand orchestration
- **Secrets**: Infisical Agent with OCI Vault bootstrap (zero secrets on disk)
- **Ingress**: Traefik reverse proxy behind OCI Load Balancer
- **Backups**: Autorestic to OCI Object Storage
- **Access**: Tailscale SSH only (no openssh-server)

## Repository Structure

```
oci-apps/
├── terraform/          # Infrastructure as Code
├── os-config/          # Butane/Ignition configuration
│   ├── butane.yaml     # Main OS config
│   ├── scripts/        # First-boot and utility scripts
│   └── systemd/        # Systemd unit files
├── docker/             # Docker Compose stacks
│   ├── infisical-agent/
│   ├── dockhand/
│   ├── traefik/
│   ├── freshrss/
│   ├── planka/
│   ├── nitter/
│   └── redlib/
└── .github/workflows/  # CI/CD pipelines
```

## Services

| Service | Description |
|---------|-------------|
| FreshRSS | RSS/Atom feed aggregator |
| FullTextRSS | Full-text feed extraction |
| Planka | Kanban board |
| Nitter | Twitter frontend |
| Redlib | Reddit frontend |

## Prerequisites

- Terraform >= 1.10
- Infisical CLI
- butane CLI (`brew install butane`)
- Access to OCI tenancy with oci-core infrastructure deployed

## Local Development

```bash
make init              # Initialize Terraform
make plan              # Run Terraform plan
make apply             # Apply changes
make fmt               # Format Terraform files
make validate          # Validate configuration
make ignition-validate # Validate Butane/Ignition config
make ignition-serve    # Generate and serve Ignition for local VM testing
```

## Secrets Management

Secrets flow through three stages:

1. **Infisical** (source of truth) → GHA workflow fetches via OIDC
2. **OCI Vault** (bootstrap only) → Terraform writes, instance reads via instance principal
3. **Infisical Agent** (runtime) → Syncs secrets to Docker volumes

No secrets are baked into images or persisted to disk.

## Deployment

Deployments are triggered automatically:
- **Feature branches**: Run pre-commit + terraform plan (posts to PR)
- **Tags (v*)**: Run terraform apply

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.10 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.0 |
| <a name="requirement_ct"></a> [ct](#requirement\_ct) | ~> 0.14 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 7.0 |
| <a name="requirement_tailscale"></a> [tailscale](#requirement\_tailscale) | ~> 0.25 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 5.16.0 |
| <a name="provider_ct"></a> [ct](#provider\_ct) | 0.14.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |
| <a name="provider_oci"></a> [oci](#provider\_oci) | 7.32.0 |
| <a name="provider_tailscale"></a> [tailscale](#provider\_tailscale) | 0.25.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudflare_dns_record.services](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record) | resource |
| [cloudflare_origin_ca_certificate.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/origin_ca_certificate) | resource |
| [cloudflare_ruleset.zone_level_waf](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset) | resource |
| [null_resource.regenerate_key](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [oci_core_instance.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance) | resource |
| [oci_core_network_security_group.instance](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group.lb](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group_security_rule.instance_egress](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.instance_ingress_http](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.lb_egress](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.lb_ingress](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_identity_dynamic_group.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_dynamic_group) | resource |
| [oci_identity_policy.storage_access](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_policy) | resource |
| [oci_identity_policy.storage_service](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_policy) | resource |
| [oci_identity_policy.vault_read_secrets](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/identity_policy) | resource |
| [oci_kms_key.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/kms_key) | resource |
| [oci_kms_key.vault](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/kms_key) | resource |
| [oci_kms_vault.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/kms_vault) | resource |
| [oci_load_balancer.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/load_balancer) | resource |
| [oci_load_balancer_backend.traefik](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/load_balancer_backend) | resource |
| [oci_load_balancer_backend_set.traefik](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/load_balancer_backend_set) | resource |
| [oci_load_balancer_certificate.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/load_balancer_certificate) | resource |
| [oci_load_balancer_listener.https](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/load_balancer_listener) | resource |
| [oci_objectstorage_bucket.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_bucket) | resource |
| [oci_objectstorage_object.bootstrap_config](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_object) | resource |
| [oci_objectstorage_object.templated_config](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_object) | resource |
| [oci_vault_secret.bootstrap](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/vault_secret) | resource |
| [tailscale_tailnet_key.this](https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/tailnet_key) | resource |
| [tls_cert_request.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [cloudflare_ip_ranges.current](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/ip_ranges) | data source |
| [cloudflare_zone.selected](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/zone) | data source |
| [ct_config.ignition](https://registry.terraform.io/providers/poseidon/ct/latest/docs/data-sources/config) | data source |
| [oci_core_images.fcos](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_images) | data source |
| [oci_core_subnet.public](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_subnet) | data source |
| [oci_identity_compartment.terraform](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_compartment) | data source |
| [oci_objectstorage_namespace.terraform](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/objectstorage_namespace) | data source |
| [terraform_remote_state.oci_core](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_domain"></a> [availability\_domain](#input\_availability\_domain) | Availability domain where instance will be launched | `string` | n/a | yes |
| <a name="input_boot_volume_size"></a> [boot\_volume\_size](#input\_boot\_volume\_size) | Boot volume size in GB | `number` | `50` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name for the bucket (defaults to {name}) | `string` | `""` | no |
| <a name="input_cloudflare_custom_list"></a> [cloudflare\_custom\_list](#input\_cloudflare\_custom\_list) | The name of the custom list in CloudFlare containing trusted IP ranges | `string` | n/a | yes |
| <a name="input_infisical_client_id"></a> [infisical\_client\_id](#input\_infisical\_client\_id) | Infisical Universal Auth client ID | `string` | n/a | yes |
| <a name="input_infisical_client_secret"></a> [infisical\_client\_secret](#input\_infisical\_client\_secret) | Infisical Universal Auth client secret | `string` | n/a | yes |
| <a name="input_instance_ocpus"></a> [instance\_ocpus](#input\_instance\_ocpus) | Number of OCPUs to allocate to the instance | `number` | `1` | no |
| <a name="input_instance_ram"></a> [instance\_ram](#input\_instance\_ram) | RAM in GB to allocate to the instance | `number` | `6` | no |
| <a name="input_instance_shape"></a> [instance\_shape](#input\_instance\_shape) | Instance shape (default is always free ARM) | `string` | `"VM.Standard.A1.Flex"` | no |
| <a name="input_lb_bandwidth"></a> [lb\_bandwidth](#input\_lb\_bandwidth) | Load balancer bandwidth in Mbps (default is always free) | `number` | `10` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for all resources | `string` | `"oci-apps"` | no |
| <a name="input_oci_fingerprint"></a> [oci\_fingerprint](#input\_oci\_fingerprint) | Fingerprint of the key used to authenticate with OCI | `string` | n/a | yes |
| <a name="input_oci_private_key"></a> [oci\_private\_key](#input\_oci\_private\_key) | Private key to authenticate with OCI | `string` | n/a | yes |
| <a name="input_oci_region"></a> [oci\_region](#input\_oci\_region) | OCI region for resources | `string` | n/a | yes |
| <a name="input_oci_tenancy_id"></a> [oci\_tenancy\_id](#input\_oci\_tenancy\_id) | OCI tenancy ID | `string` | n/a | yes |
| <a name="input_oci_user_id"></a> [oci\_user\_id](#input\_oci\_user\_id) | OCI user ID for Terraform | `string` | n/a | yes |
| <a name="input_private_key_pem"></a> [private\_key\_pem](#input\_private\_key\_pem) | Base64 encoded private key PEM for TLS certificate | `string` | n/a | yes |
| <a name="input_remote_state_endpoint"></a> [remote\_state\_endpoint](#input\_remote\_state\_endpoint) | S3-compatible endpoint for remote state | `string` | n/a | yes |
| <a name="input_restic_password"></a> [restic\_password](#input\_restic\_password) | Restic repository encryption password | `string` | n/a | yes |
| <a name="input_services"></a> [services](#input\_services) | Service configuration map | <pre>map(object({<br/>    port      = number<br/>    subdomain = string<br/>    waf_block = optional(bool, false)<br/>  }))</pre> | <pre>{<br/>  "freshrss": {<br/>    "port": 80,<br/>    "subdomain": "rss"<br/>  },<br/>  "fulltextrss": {<br/>    "port": 3000,<br/>    "subdomain": "ftr"<br/>  },<br/>  "nitter": {<br/>    "port": 8080,<br/>    "subdomain": "nitter",<br/>    "waf_block": true<br/>  },<br/>  "planka": {<br/>    "port": 1337,<br/>    "subdomain": "planka"<br/>  },<br/>  "redlib": {<br/>    "port": 8081,<br/>    "subdomain": "redlib",<br/>    "waf_block": true<br/>  }<br/>}</pre> | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | CloudFlare zone ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
