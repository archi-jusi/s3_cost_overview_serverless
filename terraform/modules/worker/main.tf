# AWS glue

resource "aws_glue_catalog_database" "aws_glue_db" {
  name = "${var.project}-glue-db"
}

resource "aws_iam_role" "gluerole" {
  name = "${var.project}-${var.environment}-role"
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

resource "aws_iam_policy" "policyglue" {
  name        = "${var.project}-${var.environment}-glue-policy"
  description = "Policy used by glue crawler"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "${var.arns3}"
            ]
        }
    ]
  })
}










