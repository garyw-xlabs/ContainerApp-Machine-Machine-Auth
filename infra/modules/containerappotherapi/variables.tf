variable "environment" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "containerapp_env_id" {
  type = string
}


variable "resource_token" {
  type = string
}
variable "location" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

variable "registry_name" {
  type = string
}
variable "image_name" {
  type = string
}
variable "api_sp_id" {
  type= string
}
variable "api_sp_client_id" {
  type= string
}
variable "api_uri"{
  type =string
}

