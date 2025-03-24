terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.26.0"
    }
  }
}

provider "google" {
  project = "qatipv3"
  }






# local/state/remote backend/CI/CD
# gcloud auth application-default login
# project = "qatipv3"
#
resource "google_compute_network" "lab_vpc" {
 name                    = "lab-vpc3"
 auto_create_subnetworks = true
}
#
 terraform {
  backend "gcs" {
    bucket  = "terraform-state-2697"  
    prefix  = "terraform/state"
  }
 }
 

