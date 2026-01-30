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
  certificate_name   = "${var.name}-${cloudflare_origin_ca_certificate.this.id}"
  load_balancer_id   = oci_load_balancer.this.id
  private_key        = base64decode(var.private_key_pem)
  public_certificate = cloudflare_origin_ca_certificate.this.certificate

  lifecycle {
    create_before_destroy = true
  }
}
