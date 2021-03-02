terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

resource "aws_s3_bucket" "s3_backend" {
  for_each = local.bucketmap
  bucket   = "${each.value}-backend-bucket"
  acl      = "private"

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

resource "aws_s3_bucket_public_access_block" "blockbucket" {
  for_each = local.bucketmap
  bucket   = "${each.value}-backend-bucket"

  block_public_acls   = true
  block_public_policy = true
  depends_on = [
    aws_s3_bucket.s3_backend,
  ]
}


resource "aws_glue_catalog_database" "aws_glue_db" {
  name = "${local.project}-glue-db"
}

resource "aws_iam_role" "gluerole" {
  name = "${local.project}-${local.environment}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })
  tags = var.tags
}

resource "aws_iam_policy" "policy-glue" {
  name        = "${local.project}-${local.environment}-glue-policy"
  description = "Policy used by glue crawler"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.s3_backend["costbucket"].arn}*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_role_attach_policy_default" {
  role       = aws_iam_role.gluerole.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_role_attach_policy" {
  role       = aws_iam_role.gluerole.id
  policy_arn = aws_iam_policy.policy-glue.arn
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
