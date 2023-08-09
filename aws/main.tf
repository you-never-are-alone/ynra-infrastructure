provider "aws" {
  region = "eu-central-1"
}

resource "aws_dynamodb_table" "ynba-rides" {
  name           = "Rides"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }
}
