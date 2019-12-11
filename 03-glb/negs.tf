data "google_compute_network_endpoint_group" "zone_printer_neg_eu_1" {
  name = var.zone_printer_neg_eu
  zone = "europe-west2-a"
}

data "google_compute_network_endpoint_group" "zone_printer_neg_eu_2" {
  name = var.zone_printer_neg_eu
  zone = "europe-west2-b"
}

data "google_compute_network_endpoint_group" "zone_printer_neg_eu_3" {
  name = var.zone_printer_neg_eu
  zone = "europe-west2-c"
}

data "google_compute_network_endpoint_group" "zone_printer_neg_us_1" {
  name = var.zone_printer_neg_us
  zone = "us-central1-a"
}

data "google_compute_network_endpoint_group" "zone_printer_neg_us_2" {
  name = var.zone_printer_neg_us
  zone = "us-central1-b"
}

data "google_compute_network_endpoint_group" "zone_printer_neg_us_3" {
  name = var.zone_printer_neg_us
  zone = "us-central1-f"
}

data "google_compute_network_endpoint_group" "hello_app_neg_eu_1" {
  name = var.hello_app_neg_eu
  zone = "europe-west2-a"
}

data "google_compute_network_endpoint_group" "hello_app_neg_eu_2" {
  name = var.hello_app_neg_eu
  zone = "europe-west2-b"
}

data "google_compute_network_endpoint_group" "hello_app_neg_eu_3" {
  name = var.hello_app_neg_eu
  zone = "europe-west2-c"
}

data "google_compute_network_endpoint_group" "hello_app_neg_us_1" {
  name = var.hello_app_neg_us
  zone = "us-central1-a"
}

data "google_compute_network_endpoint_group" "hello_app_neg_us_2" {
  name = var.hello_app_neg_us
  zone = "us-central1-b"
}

data "google_compute_network_endpoint_group" "hello_app_neg_us_3" {
  name = var.hello_app_neg_us
  zone = "us-central1-f"
}
