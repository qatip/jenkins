provider "aws" {
  region = "us-west-2"
}
terraform {
  backend "s3" {
    bucket         = "jenkins-state-michael-2697"   
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
resource "aws_s3_bucket" "example" {
bucket = "jenkins-test-bucket-michael-2697"
}
