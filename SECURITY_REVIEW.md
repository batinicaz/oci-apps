# Security Review Items

Two items to evaluate for potential hardening. Both are currently acceptable given the architecture but could be tightened.

## 1. Traefik Forwarded Headers

**File:** `os-config/traefik-config/traefik.yml:7-8`

```yaml
forwardedHeaders:
  insecure: true
```

**Current state:** Trusts all `X-Forwarded-*` headers from any source.

**Why it's acceptable:** Traffic only reaches Traefik through the OCI load balancer, which is NSG-restricted to Cloudflare IPs only (`terraform/ingress.tf:21-37`).

**Potential hardening:** Replace `insecure: true` with `trustedIPs` specifying the OCI load balancer's internal IP or subnet. This adds defense-in-depth if the NSG rules were ever misconfigured.

```yaml
forwardedHeaders:
  trustedIPs:
    - "10.0.0.0/8"  # Adjust to match your VCN private subnet
```

## 2. Load Balancer Peer Certificate Verification

**File:** `terraform/ingress.tf:107`

```terraform
verify_peer_certificate = false
```

**Current state:** Disabled TLS peer certificate verification on the load balancer backend.

**Why it's acceptable:** The backend connection is HTTP on port 80 to Traefik (`terraform/ingress.tf:93`), so there's no certificate to verify. This setting is effectively a no-op.

**Potential hardening:** If you later switch to HTTPS between the load balancer and Traefik, enable this and configure proper certificates.
