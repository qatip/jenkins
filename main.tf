terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.17.0"
    }
  }
}

provider "google" {
  project = "qatipv3"
}

resource "google_compute_network" "lab_vpc" {
  name                    = "lab-vpc1"
  auto_create_subnetworks = true
}

#terraform {
#  backend "gcs" {
#    bucket  = "<your-state-bucket>"  # Replace with the name of your GCS bucket
#    prefix  = "terraform/state"    # The folder path in the bucket
#  }
#}




# gcloud auth application-default login
