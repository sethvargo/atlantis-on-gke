variable "region" {
  type    = "string"
  default = "us-east4"
}

variable "zone" {
  type    = "string"
  default = "us-east4-b"
}

variable "project" {
  type    = "string"
  default = ""
}

variable "billing_account" {
  type = "string"
}

variable "org_id" {
  type = "string"
}

variable "instance_type" {
  type    = "string"
  default = "n1-standard-1"
}

variable "project_services" {
  type = "list"

  default = [
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "iam.googleapis.com",
  ]
}

variable "storage_bucket_roles" {
  type = "list"

  default = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]
}

variable "kubernetes_version" {
  type    = "string"
  default = "1.9.6-gke.1"
}

variable "num_servers" {
  type    = "string"
  default = "3"
}

variable "google_account_email" {
  type = "string"
}

variable "github_token" {
  type        = "string"
  description = "GitHub token with permissions to create the demo repo."
}

variable "github_organization" {
  type        = "string"
  description = "GitHub organization to create demo repo in. Won't work with a personal account."
}

variable "atlantis_version" {
  type    = "string"
  default = "latest"
}

variable "atlantis_github_user" {
  type        = "string"
  description = "GitHub username for Atlantis."
}

variable "atlantis_github_user_token" {
  type        = "string"
  description = "GitHub token for Atlantis user."
}

variable "atlantis_repo_whitelist" {
  type        = "string"
  description = "Whitelist for what repos Atlantis will operate on, ex. github.com/sethvargo-demos/*"
}
