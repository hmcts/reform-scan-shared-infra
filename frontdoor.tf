resource "azurerm_frontdoor" "example" {
  name                                         = "reform-scan-front-door-${var.env}"
  resource_group_name                          = azurerm_resource_group.reform_scan_rg.name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "routing-rule"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["reform-scan-appgw-endpoint"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "backend-appgw"
    }
  }

  backend_pool_load_balancing {
    name = "loadbalance-setting"
  }

  backend_pool_health_probe {
    name = "health-probe-setting"
  }

  backend_pool {
    name = "backend-appgw"
    backend {
      host_header = "${local.external_hostname}"
      address     = "${local.external_hostname}"
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "loadbalance-setting"
    health_probe_name   = "health-probe-setting"
  }

  frontend_endpoint {
    name                                    = "reform-scan-appgw-endpoint"
    host_name                               = "${var.frontdoor_url}"
    custom_https_provisioning_enabled       = false
    web_application_firewall_policy_link_id = "${azurerm_frontdoor_firewall_policy.wafpolicy.id}"
    custom_https_configuration {
      certificate_source = "FrontDoor"
    }
  }
}

resource "azurerm_frontdoor_firewall_policy" "wafpolicy" {
  name                = "${replace(local.env_name, "-", "")}wafpolicy"
  resource_group_name = "${azurerm_resource_group.postfix-rg.name}"
  enabled             = true
  mode                = "Prevention"

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
  }
  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
  }
}