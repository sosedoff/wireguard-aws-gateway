terraform {
  required_version = "~> 1.2"

  required_providers {
    aws = {
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}
