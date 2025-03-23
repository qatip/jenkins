provider "google" {
  project = "<your-lab-project-id>"  # Replace with your GCP project ID
  region  = "us-west1"            # Replace with your desired GCP region
}

terraform {
  backend "gcs" {
    bucket  = "<your-state-bucket>"  # Replace with the name of your GCS bucket
    prefix  = "terraform/state"    # The folder path in the bucket
  }
}

resource "google_compute_network" "example_vpc" {
  name                    = "example-vpc"
  auto_create_subnetworks = true  # Automatically creates subnets for all regions
}

