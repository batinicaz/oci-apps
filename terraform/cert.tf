resource "tls_private_key" "origin_pull" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "origin_pull" {
  private_key_pem       = tls_private_key.origin_pull.private_key_pem
  validity_period_hours = 365 * 24
  early_renewal_hours   = 90 * 24

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_encipherment",
  ]

  subject {
    common_name  = "origin-pull.${data.cloudflare_zone.selected.name}"
    organization = var.name
  }
}

resource "cloudflare_authenticated_origin_pulls_certificate" "this" {
  zone_id     = var.zone_id
  certificate = tls_self_signed_cert.origin_pull.cert_pem
  private_key = tls_private_key.origin_pull.private_key_pem
}

resource "tls_cert_request" "this" {
  dns_names       = values(local.services)[*].fqdn
  private_key_pem = base64decode(var.private_key_pem)

  subject {
    common_name = values(local.services)[0].fqdn
  }
}

resource "cloudflare_origin_ca_certificate" "this" {
  csr                = tls_cert_request.this.cert_request_pem
  hostnames          = sort(values(local.services)[*].fqdn)
  request_type       = "origin-ecc"
  requested_validity = 365
}

resource "oci_load_balancer_certificate" "this" {
  ca_certificate     = tls_self_signed_cert.origin_pull.cert_pem
  certificate_name   = "${var.name}-aop-${substr(sha256(tls_self_signed_cert.origin_pull.cert_pem), 0, 8)}-${cloudflare_origin_ca_certificate.this.id}"
  load_balancer_id   = oci_load_balancer.this.id
  private_key        = base64decode(var.private_key_pem)
  public_certificate = cloudflare_origin_ca_certificate.this.certificate

  lifecycle {
    create_before_destroy = true
  }
}
