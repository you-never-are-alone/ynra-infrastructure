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
