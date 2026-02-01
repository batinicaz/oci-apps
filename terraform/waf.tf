locals {
  services_behind_waf = {
    for service, config in local.services :
    service => config if config.waf_block
  }
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
