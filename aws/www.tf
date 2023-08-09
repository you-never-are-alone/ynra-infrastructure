provider "aws" {
  region = "eu-central-1"
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
