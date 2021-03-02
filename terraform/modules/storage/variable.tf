
variable "bucket_name" {
  description = "name of your bucket - must be unique accross all aws"
  type        = string
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

variable "tags" {
  description = "tags for all resource in the project"
  type = map
  default = {
     env = "tesing",
     owner = "devopshandsonlab",
     terraform = "true"
     project = "s3_overview_cost_project" 
   }
}
