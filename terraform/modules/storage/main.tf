terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

resource "aws_s3_bucket" "s3_backend" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = var.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cur_report_definition 
/*
resource "aws_cur_report_definition" "report-billing-master-account" {
  report_name                =  var.report_name 
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = var.bucket_report
  s3_region                  = "eu-west-1"
  additional_artifacts       = ["ATHENA"]
}
*/
