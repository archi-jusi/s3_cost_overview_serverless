
locals {
  # concatenate current region and account ex : eu-west-1:314283085815
  currentaccountregion = join(":", [data.aws_region.current.name, data.aws_caller_identity.current.account_id])
  prefixcostreport = "s3://${var.namebucketcostreport}/${var.costprefix}/${var.costreportname}/${var.costreportname}/"
  prefixlens = "s3://${var.namebucketlens}/StorageLens/${data.aws_organizations_organization.organization.id}/${var.namelensdashboard}/V_1/reports/"
  bucketmap = {
    costbucket = var.namebucketcostreport
    lensbucket = var.namebucketlens
    athenabucket = var.namebucketathena
  }
  arncost = "arn:aws:s3:::${var.namebucketcostreport}/"
  arnlens = "arn:aws:s3:::${var.namebucketlens}/"
  accountprefix = var.organization == true ? data.aws_organizations_organization.organization.id : data.aws_caller_identity.current.account_id

}

# change if to false if account for storage lens and not organization
variable "organization" {
  description = "true if organization enable for lens or false if account only"
  type = bool
  default = true
}

variable "namelensdashboard" {
  description = "name of the lens dashboard"
  type        = string
}

variable "project" {
  description = "name of the project"
  type        = string
  default     = "aws-s3-cost-overview"
}
variable "environment" {
  description = "name of the environment"
  type        = string
  default     = "test"
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
