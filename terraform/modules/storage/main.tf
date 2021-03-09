terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}


# Get current partition - region + account 
data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy" "gluepolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# get the organization id for lens
data "aws_organizations_organization" "organization" {}

resource "aws_s3_bucket" "s3_backend" {
  for_each = local.bucketmap
  bucket   = each.value
  acl      = "private"
  
  force_destroy = true
  
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
  bucket   = each.value

  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true

  depends_on = [
    aws_s3_bucket.s3_backend  
  ]
}

# Old version not supporting storage
/*

resource "aws_glue_catalog_database" "aws_glue_db" {
  name = "${var.project}-${var.environment}-glue-db"
}
*/

resource "aws_athena_database" "dbathena" {
  name   = var.databasename
  bucket = aws_s3_bucket.s3_backend["athenabucket"].id
  force_destroy = true
  depends_on = [ 
    aws_s3_bucket.s3_backend
   ]
}

# Creation role 

resource "aws_iam_role" "gluerole" {
  name = "${var.project}-${var.environment}-role-glue"
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

resource "aws_iam_role" "gluerole-lens" {
  name = "${var.project}-${var.environment}-role-glue-lens"
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
  name = "${var.project}-${var.environment}-role-lambda"
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

resource "aws_iam_role" "lambdarole-lens" {
  name = "${var.project}-${var.environment}-role-lambda-lens"
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
  
  statement {
    actions   = ["s3:PutBucketNotification"]
    resources = ["${local.arncost}*"]
    effect = "Allow"
  }
}


data "aws_iam_policy_document" "policy-document-lambda-lens" {
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
  
  statement {
    actions   = ["s3:PutBucketNotification"]
    resources = ["${local.arnlens}*"]
    effect = "Allow"
  }
}


resource "aws_iam_policy" "policy-lambda" {
  name        = "${var.project}-${var.environment}-lambda-policy"
  description = "Policy used by lambda for cost and usage report"
  policy = data.aws_iam_policy_document.policy-document-lambda.json
}

resource "aws_iam_policy" "policy-lambda-lens" {
  name        = "${var.project}-${var.environment}-lambda-policy-lens"
  description = "Policy used by lambda for lens crawler"
  policy = data.aws_iam_policy_document.policy-document-lambda-lens.json
}

# Policy Document for Glue Crawler
data "aws_iam_policy_document" "policy-document-glue" {
  
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${local.arncost}*"]
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

data "aws_iam_policy_document" "policy-document-glue-lens" {
  
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${local.arnlens}*"]
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


# Create the policy based on the document for cost usage
resource "aws_iam_policy" "custom-policy-glue" {
  name        = "${var.project}-${var.environment}-glue-policy"
  description = "Policy used by glue crawler for cost and usage"
  policy = data.aws_iam_policy_document.policy-document-glue.json
}

# policy for the crawler for lens
resource "aws_iam_policy" "custom-policy-glue-lens" {
  name        = "${var.project}-${var.environment}-glue-policy-lens"
  description = "Policy used by glue crawler for lens"
  policy = data.aws_iam_policy_document.policy-document-glue-lens.json
}

# Attachment for Glue -

resource "aws_iam_role_policy_attachment" "glue_role_attach_policy_managed" {
  role       = aws_iam_role.gluerole.id
  policy_arn = data.aws_iam_policy.gluepolicy.arn
}
resource "aws_iam_role_policy_attachment" "glue_role_attach_policy_managed-lens" {
  role       = aws_iam_role.gluerole-lens.id
  policy_arn = data.aws_iam_policy.gluepolicy.arn
}

resource "aws_iam_role_policy_attachment" "glue_role_attach_policy_custom" {
  role       = aws_iam_role.gluerole.id
  policy_arn = aws_iam_policy.custom-policy-glue.arn
}

resource "aws_iam_role_policy_attachment" "glue_role_attach_policy_custom-lens" {
  role       = aws_iam_role.gluerole-lens.id
  policy_arn = aws_iam_policy.custom-policy-glue-lens.arn
}

 

# Attachment for Lambda
resource "aws_iam_role_policy_attachment" "lambda_role_attach_policy" {
  role       = aws_iam_role.lambdarole.id
  policy_arn = aws_iam_policy.policy-lambda.arn
}
# Attachment for Lambda
resource "aws_iam_role_policy_attachment" "lambda_role_attach_policy-lens" {
  role       = aws_iam_role.lambdarole-lens.id
  policy_arn = aws_iam_policy.policy-lambda-lens.arn
}

# Creation of Glue crawler 
resource "aws_glue_crawler" "glue_crawler" {
  database_name = aws_athena_database.dbathena.id
  name          = "${var.project}-${var.environment}-crawler"
  role          = aws_iam_role.gluerole.id
  tags          = var.tags
  # required that cost report are using prefix cost - the partition after the prefix is done by AWS 
  s3_target {
    path       = local.prefixcostreport
    exclusions = ["**.json", "**.yml", "**.sql", "**.csv", "**.gz", "**.zip"]
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }
  depends_on = [
    aws_athena_database.dbathena,
    aws_iam_role.gluerole
  ]
}
# Crawler for s3 lens

resource "aws_glue_crawler" "glue_crawler-lens" {
  database_name = aws_athena_database.dbathena.id
  name          = "${var.project}-${var.environment}-crawler-lens"
  role          = aws_iam_role.gluerole-lens.id
  tags          = var.tags
  # required that cost report are using prefix cost - the partition after the prefix is done by AWS 
  s3_target {
    path       = local.prefixlens
    exclusions = ["**.json", "**.yml", "**.sql", "**.csv", "**.gz", "**.zip"]
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }
  table_prefix = "lens"
  depends_on = [
    aws_athena_database.dbathena,
    aws_iam_role.gluerole-lens
  ]
}


## Preparation for Lambda 

data "archive_file" "lambda_zip_runglue" {
  type        = "zip"
  source_file = "${path.module}/lambdafunction/runglue.js"
  output_path = "${path.module}/lambdafunction/runglue.zip"

}


resource "aws_lambda_function" "lambdarungluefunction" {
  filename      = "${path.module}/lambdafunction/runglue.zip"
  description   = "Lambda function for run glue crawler"
  function_name = "${var.project}-${var.environment}-lambdarungluecrawler"
  role          = aws_iam_role.lambdarole.arn

  # handler name need to be the same as the filename
  handler       = "runglue.handler"
  
  timeout = 120
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

resource "aws_lambda_function" "lambdarungluefunction-lens" {
  filename      = "${path.module}/lambdafunction/runglue.zip"
  description   = "Lambda function for run glue crawler for lens"
  function_name = "${var.project}-${var.environment}-lambdarungluecrawler-lens"
  role          = aws_iam_role.lambdarole-lens.arn

  # handler name need to be the same as the filename
  handler       = "runglue.handler"
  
  timeout = 120
  runtime = "nodejs10.x"
  
  environment {
    variables = {
      CRAWLNAME = aws_glue_crawler.glue_crawler-lens.id
    }
  }
  tags = var.tags
  
  depends_on = [
    aws_iam_role.lambdarole-lens,
  ]
}


resource "aws_lambda_permission" "allow_bucket_event_notification" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdarungluefunction.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_backend["costbucket"].arn
  depends_on = [ 
    aws_s3_bucket.s3_backend,
   ]
}

resource "aws_lambda_permission" "allow_bucket_event_notification-lens" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdarungluefunction-lens.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_backend["lensbucket"].arn
  depends_on = [ 
    aws_s3_bucket.s3_backend,
   ]

}


resource "aws_s3_bucket_notification" "bucket_notification_cost_report" {
  bucket = aws_s3_bucket.s3_backend["costbucket"].id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambdarungluefunction.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.costprefix}/${var.costreportname}/${var.costreportname}/"
    filter_suffix       = ".parquet"
  }

  depends_on = [
    aws_lambda_permission.allow_bucket_event_notification,
    aws_s3_bucket.s3_backend["costbucket"]
    ]
}

resource "aws_s3_bucket_notification" "bucket_notification-lens" {

  bucket = aws_s3_bucket.s3_backend["lensbucket"].id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambdarungluefunction-lens.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "StorageLens/${local.accountprefix}/${var.namelensdashboard}/V_1/reports/"
    filter_suffix       = ".par"
  }

  depends_on = [
    aws_lambda_permission.allow_bucket_event_notification-lens,
    aws_s3_bucket.s3_backend["lensbucket"]
    ]
}

resource "aws_athena_workgroup" "workgroupcostathena" {
  name = var.workgroupname
  force_destroy = true
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.namebucketathena}/output/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
  depends_on = [ 
    aws_s3_bucket.s3_backend,
   ]
   tags = var.tags
}


resource "aws_athena_named_query" "sqlcostview" {
  name      = "1-create light view for cost usage"
  workgroup = aws_athena_workgroup.workgroupcostathena.id
  database  = aws_athena_database.dbathena.name
  query     = templatefile("${path.module}/sqlquery/1_createcostlightview.sql", { db = aws_athena_database.dbathena.name, table = var.costreportname })
}

resource "aws_athena_named_query" "sqllensview" {
  name      = "2-create light view for lens"
  workgroup = aws_athena_workgroup.workgroupcostathena.id
  database  = aws_athena_database.dbathena.name
  query     = templatefile("${path.module}/sqlquery/2_createviewstoragelens.sql", { db = aws_athena_database.dbathena.name}) 
}

resource "aws_athena_named_query" "sqljoinview" {
  name      = "3-create join view"
  workgroup = aws_athena_workgroup.workgroupcostathena.id
  database  = aws_athena_database.dbathena.name
  query     = templatefile("${path.module}/sqlquery/3_createjointableview.sql", { db = aws_athena_database.dbathena.name}) 
}

resource "aws_athena_named_query" "sqlselectglobalview" {
  name      = "4-select global view"
  workgroup = aws_athena_workgroup.workgroupcostathena.id
  database  = aws_athena_database.dbathena.name
  query     = templatefile("${path.module}/sqlquery/4_select_all_view.sql" , { db = aws_athena_database.dbathena.name}) 
}

