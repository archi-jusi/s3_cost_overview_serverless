terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

# Get current partition - region + account 
data "aws_partition" "current" {
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}



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
  name = "${local.project}-${local.environment}-glue-db"
}

# Creation role 

resource "aws_iam_role" "gluerole" {
  name = "${local.project}-${local.environment}-role-glue"
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

resource "aws_iam_role" "lambdarole" {
  name = "${local.project}-${local.environment}-role-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

# Creation policy document for lambda 
# 

data "aws_iam_policy_document" "policy-document-lambda" {
  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${local.currentaccountregion}:*"]
    effect = "Allow"
  }
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.currentaccountregion}:log-group:*"]
    effect = "Allow"
  }

  statement {
    actions   = ["glue:StartCrawler"]
    resources = ["*"]
    effect = "Allow"
  }
  
  # ! need to change the resource permission for s3
  statement {
    actions   = ["s3:PutBucketNotification"]
    resources = ["arn:aws:s3:::*"]
    effect = "Allow"
  }
}


resource "aws_iam_policy" "policy-lambda" {
  name        = "${local.project}-${local.environment}-lambda-policy"
  description = "Policy used by lambda"
  policy = data.aws_iam_policy_document.policy-document-lambda.json
}

# Policy Document for Glue 
data "aws_iam_policy_document" "policy-document-glue" {
  # ! need to change the resource permission for s3
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::*"]
    effect = "Allow"
  }
  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${local.currentaccountregion}:*"]
    effect = "Allow"
  }
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.currentaccountregion}:log-group:*"]
    effect = "Allow"
  }
  
  statement {
    actions   = ["glue:UpdateDatabase", "glue:UpdatePartition", "glue:CreateTable", "glue:UpdateTable", "glue:ImportCatalogToGlue"]
    resources = ["*"]
    effect = "Allow"
  }
}

# Create the policy based on the document
resource "aws_iam_policy" "policy-glue" {
  name        = "${local.project}-${local.environment}-glue-policy"
  description = "Policy used by glue crawler"
  policy = data.aws_iam_policy_document.policy-document-glue.json
}

# Attachment for Glue 

resource "aws_iam_role_policy_attachment" "glue_role_attach_policy" {
  role       = aws_iam_role.gluerole.id
  policy_arn = aws_iam_policy.policy-glue.arn
}

# Attachment for Lambda
resource "aws_iam_role_policy_attachment" "lambda_role_attach_policy" {
  role       = aws_iam_role.lambdarole.id
  policy_arn = aws_iam_policy.policy-lambda.arn
}

# Creation of Glue crawler 
resource "aws_glue_crawler" "glue_crawler" {
  database_name = aws_glue_catalog_database.aws_glue_db.id
  name          = "${local.project}-${local.environment}-crawler"
  role          = aws_iam_role.gluerole.id
  tags          = var.tags
  # required that cost report are using prefix cost - the partition after the prefix is done by AWS 
  s3_target {
    path       = "s3://${aws_s3_bucket.s3_backend["costbucket"].id}/${var.costprefix}/partition/report-daily-partition/report-daily-partition"
    exclusions = ["**.json", "**.yml", "**.sql", "**.csv", "**.gz", "**.zip"]
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }
  depends_on = [
    aws_glue_catalog_database.aws_glue_db,
    aws_iam_role.gluerole
  ]
}


## Preparation for Lambda 

data "archive_file" "lambda_zip_runglue" {
  type        = "zip"
  source_file = "${path.module}/runglue.js"
  output_path = "${path.module}/runglue.zip"

}


resource "aws_lambda_function" "lambdarungluefunction" {
  filename      = "${path.module}/runglue.zip"
  description   = "Lambda function for run glue crawler"
  function_name = "${local.project}-${local.environment}-lambdarungluecrawler"
  role          = aws_iam_role.lambdarole.arn

  # handler name need to be the same as the filename
  handler       = "runglue.handler"
  
  #timeout = 120
  runtime = "nodejs10.x"
  
  environment {
    variables = {
      CRAWLNAME = aws_glue_crawler.glue_crawler.id
    }
  }
  tags = var.tags
  
  depends_on = [
    aws_iam_role.lambdarole,
  ]
}

resource "aws_lambda_permission" "allow_bucket_event_notification" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdarungluefunction.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_backend["costbucket"].arn
}

resource "aws_s3_bucket_notification" "bucket_notification_cost_report" {
  bucket = aws_s3_bucket.s3_backend["costbucket"].id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambdarungluefunction.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.costprefix}/partition/report-daily-partition/report-daily-partition/"
    filter_suffix       = ".parquet"
  }

  depends_on = [aws_lambda_permission.allow_bucket_event_notification]
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
