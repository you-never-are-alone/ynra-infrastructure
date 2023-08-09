provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "ynra"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "ynra-infrastructure"
    }
  }
}

resource "aws_s3_bucket" "www-bucket" {
  bucket = "ynra-www"

}

resource "aws_s3_bucket_website_configuration" "www-bucket" {
  bucket = aws_s3_bucket.www-bucket.id

  index_document {
    suffix = "index.html"
  }
}
