locals {
  default_tags      = var.default_tags
  current_commit_id = var.latest_commit_id != "" ? var.latest_commit_id : var.blue_commit_id
}
