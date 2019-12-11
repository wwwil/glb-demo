terraform {
  required_version = "~> 0.12"
}

provider "google" {
  version = 3.1
  project = "jetstack-wil"
  region  = "global"
}

output "glb_demo_address" {
  value = google_compute_global_address.glb_demo.address
}

variable "zone_printer_neg_eu" {
  type = string
}

variable "zone_printer_neg_us" {
  type = string
}

variable "hello_app_neg_eu" {
  type = string
}

variable "hello_app_neg_us" {
  type = string
}
