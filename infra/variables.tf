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
variable "otherapi_image" {
  type = string
}