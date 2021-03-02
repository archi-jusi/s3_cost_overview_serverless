
variable "bucket_name" {
  description = "name of your bucket - must be unique accross all aws"
  type        = string
}

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
