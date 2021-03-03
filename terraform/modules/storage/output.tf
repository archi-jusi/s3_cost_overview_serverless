output "bucket_name" {
  description = "name of the bucket"
  value       = values(aws_s3_bucket.s3_backend)[*].id
}
output "arn" {
  description = "ARN of the bucket"
  value       = values(aws_s3_bucket.s3_backend)[*].arn
}
output "regionbucket" {
  description = "region of the bucket"
  value       = values(aws_s3_bucket.s3_backend)[*].region
}

output "rendered_lambda_json_policy" {
  description = "lambda json policy"
  value = data.aws_iam_policy_document.policy-document-lambda.json
}

output "rendered_glue_json_policy" {
  description = "lambda json policy"
  value = data.aws_iam_policy_document.policy-document-glue.json
}
output "currentpartition"  {
  description = "current partition"
  value = local.currentaccountregion
}

output "currentregion"  {
  description = "current region"
  value = data.aws_region.current.name
}
output "currentaccount"  {
  description = "current account"
  value = data.aws_caller_identity.current.account_id
}
output "gluecrawler"  {
  description = "glue crawler name"
  value = aws_glue_crawler.glue_crawler.id
}
output "databaseforathena" {
  description = "DB destination for crawl"
  value = aws_glue_catalog_database.aws_glue_db.id
}
