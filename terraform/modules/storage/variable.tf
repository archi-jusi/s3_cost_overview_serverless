
locals {
  project     = "aws-s3-cost-overview"
  environment = "test"
  bucketmap = {
    costbucket   = "${local.project}-${local.environment}-costexplorer"
    lensbucket   = "${local.project}-${local.environment}-storagelens"
    athenabucket = "${local.project}-${local.environment}-athena"
  }
  # concatenate current region and account ex : eu-west-1:314283085815
  currentaccountregion = join(":", [data.aws_region.current.name, data.aws_caller_identity.current.account_id])
  
}


variable "costprefix" {
  description = "prefix used during creation of billing and cost report"
  type        = string
  default     = "cost"
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
