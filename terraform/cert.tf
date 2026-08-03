data "http" "cloudflare_origin_pull_ca" {
  url = "https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Fetch of Cloudflare origin pull CA failed (status ${self.status_code})."
    }
  }
}

data "tls_certificate" "cloudflare_origin_pull_ca" {
  content = data.http.cloudflare_origin_pull_ca.response_body

  lifecycle {
    postcondition {
      condition     = self.certificates[0].is_ca
      error_message = "Fetched certificate is not a CA certificate — expected Cloudflare's origin pull root CA."
    }
    postcondition {
      condition     = strcontains(self.certificates[0].subject, "CloudFlare")
      error_message = "Fetched certificate subject does not mention CloudFlare (got: ${self.certificates[0].subject}) — refusing to trust an unexpected issuer."
    }
    postcondition {
      condition     = timecmp(self.certificates[0].not_after, timestamp()) > 0
      error_message = "Fetched Cloudflare origin pull CA has expired (not_after: ${self.certificates[0].not_after}) — Cloudflare may have rotated it; verify manually before proceeding."
    }
  }
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
  ca_certificate     = trimspace(data.tls_certificate.cloudflare_origin_pull_ca.certificates[0].cert_pem)
  certificate_name   = "${var.name}-aop-${cloudflare_origin_ca_certificate.this.id}"
  load_balancer_id   = oci_load_balancer.this.id
  private_key        = base64decode(var.private_key_pem)
  public_certificate = cloudflare_origin_ca_certificate.this.certificate

  lifecycle {
    create_before_destroy = true
  }
}
