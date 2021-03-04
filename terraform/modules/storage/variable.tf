
locals {
  # concatenate current region and account ex : eu-west-1:314283085815
  currentaccountregion = join(":", [data.aws_region.current.name, data.aws_caller_identity.current.account_id])
  prefixcostreport = "s3://${var.namebucketcostreport}/${var.costprefix}/${var.costreportname}/${var.costreportname}/"
  bucketmap = {
    costbucket = "${var.namebucketcostreport}"
    lensbucket = "${var.namebucketlens}"
    athenabucket = "${var.namebucketathena}"
  }
  arncost = "arn:aws:s3:::${var.namebucketcostreport}"
}

variable "project" {
  description = "name of the project"
  type        = string
  default     = "aws-s3-cost-overview"
}
variable "environment" {
  description = "name of the environment"
  type        = string
  default     = "staging"
}

variable "namebucketcostreport" {
  description = "name of the bucket for reporting report"
  type        = string
  default     = "staging-aws-s3-cost-overview-cost"
}

variable "costprefix" {
  description = "name of the prefix used in the cost and usage report"
  type        = string
  default     = "prefix"
}

variable "costreportname" {
  description = "name of the cost and usage report"
  type        = string
  default     = "costreport"
}

variable "namebucketathena" {
  description = "name of the bucket for athena"
  type        = string
  default     = "staging-aws-s3-cost-overview-athena"
}

variable "namebucketlens" {
  description = "name of the bucket for storage lens"
  type        = string
  default     = "staging-aws-s3-cost-overview-lens"
}



variable "tags" {
  description = "tags for all resource in the project"
  type        = map(any)
  default = {
    env       = "test",
    owner     = "devopshandsonlab",
    terraform = "true"
    project   = "s3_overview_cost_project"
  }
}
