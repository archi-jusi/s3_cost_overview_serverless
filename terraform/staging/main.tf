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
  source               = "../modules/storage/"
  project              = "aws-s3-cost"
  environment          = "staging"
  namebucketcostreport = "staging-cost-bucket"
  namebucketathena     = "staging-cost-athena"
  namebucketlens       = "staging-cost-lens"
  namelensdashboard    = "dashboard-lens-staging"
  costprefix           = "cost"
  costreportname       = "costreport"
  workgroupname        = "workgroupcostathena"
  databasename         = "database_terraform"
  organization         = false
  tags = {
    env       = "staging",
    owner     = "devopshandsonlab",
    terraform = "true"
    project   = "s3_overview_cost_project"
  }
}

