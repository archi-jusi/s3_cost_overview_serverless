
locals {
  project     = "aws-s3-cost-overview"
  environment = "test"
  bucketmap = {
    costbucket   = "${local.project}-${local.environment}-costexplorer"
    lensbucket   = "${local.project}-${local.environment}-storagelens"
    athenabucket = "${local.project}-${local.environment}-athena"
  }
}

/*
variable "bucket_report" {
  description = "name of your bucket for cost report" 
  type        = string
}

variable "report_name" {
  description = "name of your cost and billing report"
  type        = string
}

variable "region" {
  description = "region for s3"
  type = string
  default = "us-east-1"
}
*/

variable "costprefix" {
  description = "prefix used during creation of billing and cost report"
  type        = string
  default     = "cost"
}


variable "tags" {
  description = "tags for all resource in the project"
  type        = map(any)
  default = {
    env       = "tesing",
    owner     = "devopshandsonlab",
    terraform = "true"
    project   = "s3_overview_cost_project"
  }
}
