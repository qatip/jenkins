provider "aws" {
  region = "us-east-1"
}
terraform {
  backend "s3" {
    bucket         = "statefile-michael-2697"   
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
resource "aws_s3_bucket" "example" {
  bucket = "jenkins-test-bucket-michael1-69712"
}
