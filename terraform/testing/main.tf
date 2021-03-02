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
  region = "us-east-1"
  profile = "s3cost"
}


module "aws_s3_backend" {
  source = "../modules/storage/"
  for_each = {
    costexplorerbucket = "${local.project}-${local.environment}-costexplorer"
    storagelensbucket =   "${local.project}-${local.environment}-storagelens"
  }
  bucket_name = "${each.value}-backend-bucket"
  #bucket_report  = module.aws_s3_backend["costexplorerbucket"]
  #report_name = "${local.project}-${local.environment}-report"
}

resource "aws_cur_report_definition" "report-billing-master-account" {
  report_name                =  "billing_test"
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = "${local.project}-${local.environment}-costexplorer"
  s3_region                  = "us-east-1"
  s3_prefix                  = "report"
  additional_artifacts       = ["ATHENA"]
  report_versioning	     = "OVERWRITE_REPORT"
}

