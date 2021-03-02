
variable "tags" {
  description = "tags for all resource in the project"
  type = map
  default = {
     env = "test" ,
     owner = "devopshandsonlab" ,
     terraform = "true"
     project = "testing-project"
  }
}
variable "namebucketstate" {
  description = "name for the bucket state"
  type = string
  default = "testing-terraform-state"
}
variable "namedynamodbtable" {
  description = "name for the locking dynamodb table"
  type = string
  default = "project-env-terraform-state"
}
