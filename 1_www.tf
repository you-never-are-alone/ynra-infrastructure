resource "aws_s3_bucket" "www-bucket" {
  bucket = "www.${var.domainName}"
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

data "aws_iam_policy_document" "allow_public_access" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.www-bucket.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "www-bucket-policy" {
  bucket = aws_s3_bucket.www-bucket.id
  policy = data.aws_iam_policy_document.allow_public_access.json
}

#######################################################################
# connect with domain

resource "aws_route53_zone" "main" {
  name = var.domainName
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.id
  name    = "www.${var.domainName}"
  type    = "A"

  alias {
    evaluate_target_health = false
    name                   = aws_s3_bucket_website_configuration.www-bucket.website_domain
    zone_id                = aws_s3_bucket.www-bucket.hosted_zone_id
  }
}

resource "aws_route53_record" "basic" {
  zone_id = aws_route53_zone.main.id
  name    = aws_route53_zone.main.name
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_s3_bucket_website_configuration.www-bucket.website_endpoint
    zone_id                = aws_s3_bucket.www-bucket.hosted_zone_id
  }
}

# Deployment user
#
# We create a key from this user for the deployment pipeline.

resource "aws_iam_user" "deployer-www" {
  name = "deployer-www"
}

data "aws_iam_policy_document" "deployer-www" {
  statement {
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.www-bucket.arn}/*",
      aws_s3_bucket.www-bucket.arn,
    ]
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:ListBucket",
    ]
  }
}

resource "aws_iam_user_policy" "deployer-www" {
  name   = "deployer-www-policy"
  user   = aws_iam_user.deployer-www.name
  policy = data.aws_iam_policy_document.deployer-www.json
}
