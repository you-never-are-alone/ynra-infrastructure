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

resource "aws_s3_bucket_ownership_controls" "www-bucket" {
  bucket = aws_s3_bucket.www-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "www-bucket" {
  bucket = aws_s3_bucket.www-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "www-bucket-acl" {
  bucket = aws_s3_bucket.www-bucket.id

  depends_on = [
    aws_s3_bucket_ownership_controls.www-bucket,
    aws_s3_bucket_public_access_block.www-bucket
  ]
  acl = "public-read"
}
