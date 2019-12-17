resource "google_compute_global_address" "glb_demo" {
  name = "glb-demo"
}

resource "google_compute_global_forwarding_rule" "glb_demo_http" {
  name                  = "glb-demo-http"
  ip_address            = google_compute_global_address.glb_demo.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.glb_demo.self_link
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_target_http_proxy" "glb_demo" {
  name = "glb-demo"

  url_map = google_compute_url_map.glb_demo.self_link
}

resource "google_compute_global_forwarding_rule" "glb_demo_https" {
  name                  = "glb-demo-https"
  ip_address            = google_compute_global_address.glb_demo.address
  port_range            = "443"
  target                = google_compute_target_https_proxy.glb_demo.self_link
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_ssl_certificate" "glb_demo" {
  name_prefix = "glb-demo-"
  private_key = file("example.key")
  certificate = file("example.crt")
}

resource "google_compute_target_https_proxy" "glb_demo" {
  name = "glb-demo"

  ssl_certificates = [google_compute_ssl_certificate.glb_demo.self_link]
  url_map          = google_compute_url_map.glb_demo.self_link
}

resource "google_compute_url_map" "glb_demo" {
  name            = "glb-demo"
  default_service = google_compute_backend_service.glb_demo_zone_printer.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "glb-demo"
  }

  path_matcher {
    name            = "glb-demo"
    default_service = google_compute_backend_service.glb_demo_zone_printer.self_link

    path_rule {
      paths   = ["/hello-app"]
      service = google_compute_backend_service.glb_demo_hello_app.self_link
    }
  }
}

# The max_rate for these backends is set to the minimum so that simply by
# aggressively refreshing the page traffic will be sent to different instances
# in different zones to demonstrate the load balancer in operation.

resource "google_compute_backend_service" "glb_demo_zone_printer" {
  name                  = "glb-demo-zone-printer"
  health_checks         = [google_compute_health_check.glb_demo.self_link]
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  port_name             = "http"
  security_policy       = google_compute_security_policy.glb_demo.self_link

  backend {
    group          = data.google_compute_network_endpoint_group.zone_printer_neg_eu_1.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.zone_printer_neg_eu_2.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.zone_printer_neg_eu_3.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.zone_printer_neg_us_1.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.zone_printer_neg_us_2.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.zone_printer_neg_us_3.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }
}

resource "google_compute_backend_service" "glb_demo_hello_app" {
  name                  = "glb-demo-hello-app"
  health_checks         = [google_compute_health_check.glb_demo.self_link]
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  port_name             = "http"
  security_policy       = google_compute_security_policy.glb_demo.self_link

  backend {
    group          = data.google_compute_network_endpoint_group.hello_app_neg_eu_1.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.hello_app_neg_eu_2.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.hello_app_neg_eu_3.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.hello_app_neg_us_1.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.hello_app_neg_us_2.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }

  backend {
    group          = data.google_compute_network_endpoint_group.hello_app_neg_us_3.self_link
    balancing_mode = "RATE"
    max_rate       = 1
  }
}

resource "google_compute_health_check" "glb_demo" {
  name                = "glb-demo"
  healthy_threshold   = 1
  check_interval_sec  = 60
  unhealthy_threshold = 10
  timeout_sec         = 60

  tcp_health_check {
    port = "80"
  }
}

# This is a firewall rule to allow incoming traffic on port 80
resource "google_compute_firewall" "glb_demo" {
  name      = "glb-demo"
  network   = "default"
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # These are the source ranges for Google's network for traffic coming in from
  # the load balancer
  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
}

# This is a Cloud Armor policy
resource "google_compute_security_policy" "glb_demo" {
  name = "glb-demo"

  # Default rule, allow all traffic
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }

  # Deny traffic from some IPs
  rule {
    action = "deny(403)"
    # Lower value means higher priority
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["9.9.9.0/24"]
      }
    }
    description = "Deny access to IPs in 9.9.9.0/24"
  }

}
