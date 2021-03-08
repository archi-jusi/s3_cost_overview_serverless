terraform {
  required_version = "~>0.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}


module "aws_s3_backend" {
  #source               = "git::https://github.com/archi-jusi/s3_cost_overview_serverless.git//terraform//modules/storage?ref=v0.0.2"
  source               = "git::https://github.com/archi-jusi/s3_cost_overview_serverless.git//terraform//modules/storage"
  project              = "aws-s3-cost-prod"
  environment          = "prod"
  namebucketcostreport = "prod-cost-bucket"
  namebucketathena     = "prod-cost-athena"
  namebucketlens       = "prod-cost-lens"
  namelensdashboard    = "dashboard-lens-prod"
  costprefix           = "prodcost"
  costreportname       = "prodcostreport"
  databasename         = "prodcostdb"
  workgroupname        = "prod-workgroup-cost"
  tags = {
    env       = "prod",
    owner     = "devopshandsonlab",
    terraform = "true"
    project   = "s3_overview_cost_project"
  }
}

