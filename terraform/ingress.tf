resource "cloudflare_dns_record" "services" {
  for_each = local.services
  zone_id  = var.zone_id
  name     = each.value.subdomain
  proxied  = true
  ttl      = 1
  type     = "A"
  content  = oci_load_balancer.this.ip_address_details[0].ip_address
}

resource "oci_core_network_security_group" "lb" {
  compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name   = "${var.name}-lb"
  vcn_id         = data.terraform_remote_state.oci_core.outputs.core_vcn_id

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-lb"
  })
}

resource "oci_core_network_security_group_security_rule" "lb_ingress" {
  for_each                  = toset(data.cloudflare_ip_ranges.current.ipv4_cidrs)
  description               = "Ingress from CloudFlare"
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.lb.id
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"
  stateless                 = false

  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_egress" {
  description               = "Egress to Traefik"
  destination               = oci_core_network_security_group.instance.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.lb.id
  protocol                  = "6"
  stateless                 = false

  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}

resource "oci_load_balancer" "this" {
  compartment_id             = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name               = var.name
  ip_mode                    = "IPV4"
  is_private                 = false
  network_security_group_ids = [oci_core_network_security_group.lb.id]
  shape                      = "flexible"
  subnet_ids                 = [data.terraform_remote_state.oci_core.outputs.core_vcn_subnets["public"]]

  defined_tags = merge(local.default_tags, {
    "terraform.name" = var.name
  })

  shape_details {
    maximum_bandwidth_in_mbps = var.lb_bandwidth
    minimum_bandwidth_in_mbps = var.lb_bandwidth
  }
}

resource "oci_load_balancer_backend_set" "traefik" {
  load_balancer_id = oci_load_balancer.this.id
  name             = "traefik"
  policy           = "LEAST_CONNECTIONS"

  health_checker {
    interval_ms       = 10000
    protocol          = "TCP"
    port              = 80
    retries           = 5
    timeout_in_millis = 5000
  }
}

resource "oci_load_balancer_backend" "traefik" {
  backendset_name  = oci_load_balancer_backend_set.traefik.name
  ip_address       = oci_core_instance.this.private_ip
  load_balancer_id = oci_load_balancer.this.id
  port             = 80
}

resource "oci_load_balancer_listener" "https" {
  default_backend_set_name = oci_load_balancer_backend_set.traefik.name
  load_balancer_id         = oci_load_balancer.this.id
  name                     = "${var.name}-https"
  port                     = 443
  protocol                 = "HTTP"

  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.this.certificate_name
    cipher_suite_name       = "oci-modern-ssl-cipher-suite-v1"
    protocols               = ["TLSv1.2"]
    verify_peer_certificate = false
  }
}
