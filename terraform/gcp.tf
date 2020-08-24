provider "google" {
  region  = var.region
  project = var.project
}

resource "random_id" "random" {
  prefix      = var.project_prefix
  byte_length = "8"
}

resource "google_service_account" "account" {
  account_id   = "atlantis-server"
  display_name = "Atlantis Server"
  project = var.project
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.account.name
}

resource "google_project_iam_member" "service-account" {
  project = var.project
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = var.project
  service = element(var.project_services, count.index)

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

resource "google_storage_bucket" "bucket" {
  name = "${var.project}-state"
  project = var.project
  force_destroy = true
  storage_class = "MULTI_REGIONAL"

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.service]
}

resource "google_storage_bucket_iam_member" "sa-to-bucket" {
  count  = length(var.storage_bucket_roles)
  bucket = google_storage_bucket.bucket.name
  role   = element(var.storage_bucket_roles, count.index)
  member = "serviceAccount:${google_service_account.account.email}"
}

resource "google_compute_address" "address" {
  name    = "load-balancer"
  region  = var.region
  project = var.project

  depends_on = [google_project_service.service]
}

data "google_container_engine_versions" "versions" {
  project = var.project
  location  = var.region
}

resource "google_container_cluster" "cluster" {
  name    = "terraform-atlantis"
  project = var.project
  location  = var.region

  min_master_version = data.google_container_engine_versions.versions.latest_master_version
  node_version       = data.google_container_engine_versions.versions.latest_node_version

  logging_service    = var.kubernetes_logging_service
  monitoring_service = var.kubernetes_monitoring_service

  initial_node_count = var.kubernetes_nodes_per_zone

  node_config {
    machine_type    = var.kubernetes_instance_type
    service_account = google_service_account.account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    tags = ["atlantis", "terraform"]
  }

  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  network_policy {
    enabled = true
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.kubernetes_daily_maintenance_window
    }
  }

  depends_on = [
    google_project_service.service,
    google_storage_bucket_iam_member.sa-to-bucket,
    google_project_iam_member.service-account,
  ]
}

output "project" {
  value = var.project
}

output "region" {
  value = var.region
}

output "address" {
  value = google_compute_address.address.address
}

