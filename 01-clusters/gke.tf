resource "google_container_cluster" "glb-demo-us" {
  name               = "glb-demo-us"
  location           = "us-central1"
  initial_node_count = 3

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.1.0.0/16"
    services_ipv4_cidr_block = "10.2.0.0/16"
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}

resource "google_container_cluster" "glb-demo-eu" {
  name               = "glb-demo-eu"
  location           = "europe-west2"
  initial_node_count = 3

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.3.0.0/16"
    services_ipv4_cidr_block = "10.4.0.0/16"
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}
