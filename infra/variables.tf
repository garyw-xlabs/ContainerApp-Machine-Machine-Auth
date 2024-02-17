# Input variables for the module

variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "environment_name" {
  description = "The name of the azd environment to be deployed"
  type        = string
}
variable "api_image" {
  type = string
}
variable "latest_commit_id" {
  type = string
}

variable "blue_commit_id" {
  type    = string
  default = ""
}
variable "green_commit_id" {
  type    = string
  default = ""
}
variable "production_label" {
  type    = string
  default = "blue"
}

