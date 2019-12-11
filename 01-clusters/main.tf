terraform {
  required_version = "~> 0.12"
}

provider "google" {
  version = 3.1
  project = "jetstack-wil"
  region  = "global"
}
