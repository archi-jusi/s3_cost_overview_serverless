terraform {
  required_version = "~>0.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
}


module "aws_s3_backend" {
  source = "../modules/storage/"
}
