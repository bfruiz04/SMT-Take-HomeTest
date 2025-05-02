
# modules/load_balancer/main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# --- Reserve Global Static IP Address ---
resource "google_compute_global_address" "lb_ip" {
  project = var.project_id
  name    = "${var.lb_name}-ip"
}

# --- Serverless Network Endpoint Group (NEG) ---
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  project               = var.project_id
  name                  = "${var.lb_name}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_function {
    function = var.function_name
  }
}

# --- Backend Service ---
resource "google_compute_backend_service" "function_backend" {
  project               = var.project_id
  name                  = "${var.lb_name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
    
  }


  security_policy = var.security_policy_link
  
  # logging configuration
  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# --- URL Map ---
resource "google_compute_url_map" "lb_url_map" {
  project         = var.project_id
  name            = "${var.lb_name}-url-map"
  default_service = google_compute_backend_service.function_backend.id

  path_matcher {
    name            = "function-path-matcher"
    default_service = google_compute_backend_service.function_backend.id

    path_rule {
      paths   = ["/helloWorld"]
      service = google_compute_backend_service.function_backend.id
    }
  }
}

# --- Target HTTP Proxy ---
resource "google_compute_target_http_proxy" "http_proxy" {
  project = var.project_id
  name    = "${var.lb_name}-http-proxy"
  url_map = google_compute_url_map.lb_url_map.id
}

# --- Global Forwarding Rule ---
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  project               = var.project_id
  name                  = "${var.lb_name}-fwd-rule"
  ip_protocol           = "TCP"
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.address
  target                = google_compute_target_http_proxy.http_proxy.id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# --- Firewall Rule ---
resource "google_compute_firewall" "allow_health_checks" {
  project       = var.project_id
  name          = "${var.lb_name}-allow-hc"
  network       = "default"
  direction     = "INGRESS"
  description   = "Allow traffic from Google Cloud health checkers"

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}