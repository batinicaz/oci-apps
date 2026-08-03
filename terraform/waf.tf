locals {
  services_behind_waf = {
    for service, config in local.services :
    service => config if config.waf_block
  }

  services_rate_limited = {
    for service, config in local.services :
    service => config if length(config.rate_limit_paths) > 0
  }

  rate_limit_service_expressions = [
    for service, config in local.services_rate_limited :
    "(http.host eq \"${config.fqdn}\" and (${join(" or ", [for path in sort(config.rate_limit_paths) : "http.request.uri.path contains \"${path}\""])}))"
  ]
}

resource "cloudflare_authenticated_origin_pulls_settings" "this" {
  zone_id = var.zone_id
  enabled = true

  depends_on = [cloudflare_authenticated_origin_pulls_certificate.this]
}

resource "cloudflare_zone_setting" "tls_client_auth" {
  zone_id    = var.zone_id
  setting_id = "tls_client_auth"
  value      = "on"

  depends_on = [cloudflare_authenticated_origin_pulls_settings.this]
}

resource "cloudflare_ruleset" "zone_level_waf" {
  zone_id     = data.cloudflare_zone.selected.zone_id
  name        = "WAF for ${data.cloudflare_zone.selected.name}"
  description = "Restrict access to ${var.name} services"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules = [
    for service, config in local.services_behind_waf :
    {
      action      = "block"
      description = "Restrict external access to ${service}"
      expression  = "(http.host eq \"${config.fqdn}\" and not ip.src in ${var.cloudflare_custom_list})"
      enabled     = true
    }
  ]
}

resource "cloudflare_ruleset" "zone_level_ratelimit" {
  zone_id     = data.cloudflare_zone.selected.zone_id
  name        = "Rate limiting for ${data.cloudflare_zone.selected.name}"
  description = "Throttle login attempts on password-auth services"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = [
    {
      action      = "block"
      description = "Rate limit login POSTs"
      expression  = "(http.request.method eq \"POST\" and (${join(" or ", local.rate_limit_service_expressions)}))"
      enabled     = true
      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = 10
        requests_per_period = 5
        mitigation_timeout  = 10
      }
    }
  ]
}
