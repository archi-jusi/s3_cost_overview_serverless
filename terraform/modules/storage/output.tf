output "bucket_name" {
  description = "name of the bucket"
  value       = values(aws_s3_bucket.s3_backend)[*].id
}
output "arn" {
  description = "ARN of the bucket"
  value       = values(aws_s3_bucket.s3_backend)[*].arn
}
output "region" {
  description = "region of the bucket"
  value       = values(aws_s3_bucket.s3_backend)[*].region
}

