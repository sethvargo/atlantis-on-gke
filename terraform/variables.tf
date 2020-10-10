variable "region" {
  type    = string
  default = "us-central1"

  description = <<EOF
GCP Region in which Atlantis will run
EOF

}

variable "project" {
  type    = string
  default = ""

  description = <<EOF
Project ID of the project that Terraform is authenticated to run in to create additional
projects.
EOF

}

variable "project_prefix" {
  type    = string
  default = "atlantis-"

  description = <<EOF
Prefix value for projects that are created by Atlantis
EOF

}

variable "billing_account" {
  type = string

  description = <<EOF
GCP Billing account ID
EOF

}

variable "org_id" {
  type = string

  description = <<EOF
GCP Organization ID
EOF

}

variable "project_services" {
  type = list(string)

  default = [
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "storage_bucket_roles" {
  type = list(string)

  default = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]
}

#
# Atlantis
# --------

variable "atlantis_container" {
  type    = string
  default = "runatlantis/atlantis:latest"

  description = <<EOF
Name of the Atlantis container image to deploy. This can be specified like
"container:version" or as a full container URL.
EOF

}

variable "atlantis_github_user" {
  type = string

  description = <<EOF
The username that Atlantis will run as on Github. 
EOF

}

variable "atlantis_github_user_token" {
  type = string

  description = <<EOF
The github access token for the user that Atlantis will run as
EOF

}

variable "atlantis_repo_whitelist" {
  type = string

  description = <<EOF
Whitelist which repositories Atlantis can run on. This is specified as the
full repo URL or a wildcard splay (e.g. github.com/sethvargo-demos/*).
EOF

}

#
# GitHub
# ------

variable "github_token" {
  type = string

  description = <<EOF
GitHub token with permissions for Terraform to create the demo repo 
EOF

}

variable "github_organization" {
  type = string

  description = <<EOF
GitHub organization to create demo repo in. This will not work with a
personal GitHub account (must be an organization).
EOF

}

variable "github_repo_is_private" {
  type    = string
  default = "false"

  description = <<EOF
Whether the GitHub repository is private.
EOF

}

#
# Kubernetes/GKE
# --------------

variable "kubernetes_instance_type" {
  type    = string
  default = "n1-standard-1"

  description = <<EOF
Instance type to use for the nodes.
EOF

}

variable "kubernetes_nodes_per_zone" {
  type    = string
  default = "1"

  description = <<EOF
Number of nodes to deploy in each zone of the Kubernetes cluster. For example,
if there are 4 zones in the region and num_nodes_per_zone is 2, 8 total nodes
will be created.
EOF

}

variable "kubernetes_logging_service" {
  type    = string
  default = "logging.googleapis.com/kubernetes"

  description = <<EOF
Name of the logging service to use. By default this uses the new Stackdriver
GKE beta.
EOF

}

variable "kubernetes_monitoring_service" {
  type    = string
  default = "monitoring.googleapis.com/kubernetes"

  description = <<EOF
Name of the monitoring service to use. By default this uses the new
Stackdriver GKE beta.
EOF

}

variable "kubernetes_daily_maintenance_window" {
  type    = string
  default = "06:00"

  description = <<EOF
Maintenance window for GKE.
EOF

}
