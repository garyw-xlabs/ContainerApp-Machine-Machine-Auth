variable "environment" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "containerapp_env_id" {
  type = string
}
variable "containerapp_env_url" {
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

