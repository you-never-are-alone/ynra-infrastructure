resource "aws_s3_bucket" "app-bucket" {
  bucket = "app.${var.domainName}"
}

resource "aws_s3_bucket_website_configuration" "app-bucket" {
  bucket = aws_s3_bucket.app-bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "app-bucket" {
  bucket = aws_s3_bucket.app-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "app-bucket" {
  bucket = aws_s3_bucket.app-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "app-bucket-acl" {
  bucket = aws_s3_bucket.app-bucket.id

  depends_on = [
    aws_s3_bucket_ownership_controls.app-bucket,
    aws_s3_bucket_public_access_block.app-bucket
  ]
  acl = "public-read"
}

data "aws_iam_policy_document" "allow_public_access_app" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.app-bucket.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "app-bucket-policy" {
  bucket = aws_s3_bucket.app-bucket.id
  policy = data.aws_iam_policy_document.allow_public_access_app.json
}

#######################################################################
# connect with domain
resource "aws_route53_record" "app" {
  depends_on = [aws_route53_zone.main]
  zone_id    = aws_route53_zone.main.id
  name       = "app.${var.domainName}"
  type       = "A"

  alias {
    evaluate_target_health = false
    name                   = aws_s3_bucket_website_configuration.app-bucket.website_endpoint
    zone_id                = aws_s3_bucket.app-bucket.hosted_zone_id
  }
}

resource "aws_route53_record" "basic-app" {
  depends_on = [aws_route53_zone.main]
  zone_id    = aws_route53_zone.main.id
  name       = aws_route53_zone.main.name
  type       = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_s3_bucket_website_configuration.app-bucket.website_endpoint
    zone_id                = aws_s3_bucket.app-bucket.hosted_zone_id
  }
}

# Deployment user
#
# We create a key from this user for the deployment pipeline.

resource "aws_iam_user" "deployer-app" {
  name = "deployer-app"
}

data "aws_iam_policy_document" "deployer-app" {
  statement {
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.app-bucket.arn}/*",
      aws_s3_bucket.app-bucket.arn,
    ]
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:ListBucket",
    ]
  }
}

resource "aws_iam_user_policy" "deployer-app" {
  name   = "deployer-app-policy"
  user   = aws_iam_user.deployer-app.name
  policy = data.aws_iam_policy_document.deployer-app.json
}
