provider "aws" {
  region = "us-east-1"
}
terraform {
  backend "s3" {
    bucket         = "https://github.com/qatip/jenkins.git"   
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
  }
}
resource "aws_s3_bucket" "example" {
bucket = "jenkins-test-bucket-michael2697"
}
