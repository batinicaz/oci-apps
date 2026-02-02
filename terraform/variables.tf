variable "name" {
  type        = string
  default     = "oci-apps"
  description = "Name prefix for all resources"
}

variable "availability_domain" {
  type        = string
  description = "Availability domain where instance will be launched"
}

variable "boot_volume_size" {
  type        = number
  default     = 50
  description = "Boot volume size in GB"
}

variable "cloudflare_custom_list" {
  type        = string
  description = "The name of the custom list in CloudFlare containing trusted IP ranges"
}

variable "instance_ocpus" {
  type        = number
  default     = 1
  description = "Number of OCPUs to allocate to the instance"
}

variable "instance_ram" {
  type        = number
  default     = 6
  description = "RAM in GB to allocate to the instance"
}

variable "instance_shape" {
  type        = string
  default     = "VM.Standard.A1.Flex"
  description = "Instance shape (default is always free ARM)"
}

variable "lb_bandwidth" {
  type        = number
  default     = 10
  description = "Load balancer bandwidth in Mbps (default is always free)"
}

variable "bucket_name" {
  type        = string
  default     = ""
  description = "Name for the bucket (defaults to {name})"
}

variable "remote_state_endpoint" {
  type        = string
  sensitive   = true
  description = "S3-compatible endpoint for remote state"
}

variable "oci_fingerprint" {
  type        = string
  description = "Fingerprint of the key used to authenticate with OCI"
}

variable "oci_private_key" {
  type        = string
  sensitive   = true
  description = "Private key to authenticate with OCI"
}

variable "oci_region" {
  type        = string
  description = "OCI region for resources"
}

variable "oci_tenancy_id" {
  type        = string
  description = "OCI tenancy ID"
}

variable "oci_user_id" {
  type        = string
  description = "OCI user ID for Terraform"
}

variable "private_key_pem" {
  type        = string
  sensitive   = true
  description = "Base64 encoded private key PEM for TLS certificate"
}

variable "services" {
  type = map(object({
    port      = number
    subdomain = string
    waf_block = optional(bool, false)
  }))
  default = {
    freshrss = {
      port      = 80
      subdomain = "rss"
    }
    fulltextrss = {
      port      = 3000
      subdomain = "ftr"
    }
    planka = {
      port      = 1337
      subdomain = "planka"
    }
    nitter = {
      port      = 8080
      subdomain = "nitter"
      waf_block = true
    }
    redlib = {
      port      = 8081
      subdomain = "redlib"
      waf_block = true
    }
  }
  description = "Service configuration map"
}

variable "infisical_client_id" {
  type        = string
  sensitive   = true
  description = "Infisical Universal Auth client ID"
}

variable "infisical_client_secret" {
  type        = string
  sensitive   = true
  description = "Infisical Universal Auth client secret"
}

variable "restic_password" {
  type        = string
  sensitive   = true
  description = "Restic repository encryption password"
}

variable "zone_id" {
  type        = string
  description = "CloudFlare zone ID"
}

locals {
  default_tags = {
    "terraform.managed" = "terraform"
    "terraform.repo"    = "https://github.com/batinicaz/${var.name}"
  }

  bucket_name = var.bucket_name != "" ? var.bucket_name : var.name

  services = {
    for name, config in var.services :
    name => merge(config, {
      fqdn = "${config.subdomain}.${data.cloudflare_zone.selected.name}"
    })
  }

  service_hosts = {
    for name, config in local.services :
    "${upper(replace(name, "-", "_"))}_HOST" => config.fqdn
  }
}
