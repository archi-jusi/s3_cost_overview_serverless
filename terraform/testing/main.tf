terraform {
  required_version = "~>0.14.6"
  backend "s3" {
    bucket = "s3-cost-overview-test-listing-state"
    key    = "test/terraform.state"
    region = "eu-west-1"

    dynamodb_table = "s3-cost-overview-test-listing-state"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "s3cost"
}


module "aws_s3_backend" {
  source = "../modules/storage/"
}

