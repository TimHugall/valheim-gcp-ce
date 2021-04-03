terraform {
  backend "gcs" {
    bucket = "hugall-terraform-state"
    prefix = "terraform/valheim"
  }
}