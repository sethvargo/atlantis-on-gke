provider "google" {
  region  = "${var.region}"
  project = "${var.project}"
}

resource "random_id" "random" {
  prefix      = "${var.project_prefix}"
  byte_length = "8"
}

resource "google_project" "project" {
  name            = "${random_id.random.hex}"
  project_id      = "${random_id.random.hex}"
  org_id          = "${var.org_id}"
  billing_account = "${var.billing_account}"
}

resource "google_service_account" "account" {
  account_id   = "atlantis-server"
  display_name = "Atlantis Server"
  project      = "${google_project.project.project_id}"
}

resource "google_service_account_key" "key" {
  service_account_id = "${google_service_account.account.name}"
}

resource "google_project_iam_member" "service-account" {
  project = "${google_project.project.project_id}"
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.account.email}"
}

resource "google_project_service" "service" {
  count   = "${length(var.project_services)}"
  project = "${google_project.project.project_id}"
  service = "${element(var.project_services, count.index)}"

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

resource "google_storage_bucket" "bucket" {
  name          = "${google_project.project.project_id}-state"
  project       = "${google_project.project.project_id}"
  force_destroy = true
  storage_class = "MULTI_REGIONAL"

  versioning {
    enabled = true
  }

  depends_on = ["google_project_service.service"]
}

resource "google_storage_bucket_iam_member" "sa-to-bucket" {
  count  = "${length(var.storage_bucket_roles)}"
  bucket = "${google_storage_bucket.bucket.name}"
  role   = "${element(var.storage_bucket_roles, count.index)}"
  member = "serviceAccount:${google_service_account.account.email}"
}

resource "google_compute_address" "address" {
  name    = "load-balancer"
  region  = "${var.region}"
  project = "${google_project.project.project_id}"

  depends_on = ["google_project_service.service"]
}

data "google_container_engine_versions" "versions" {
  project = "${google_project.project.project_id}"
  region  = "${var.region}"
}

resource "google_container_cluster" "cluster" {
  name    = "terraform-atlantis"
  project = "${google_project.project.project_id}"
  region  = "${var.region}"

  min_master_version = "${data.google_container_engine_versions.versions.latest_master_version}"
  node_version       = "${data.google_container_engine_versions.versions.latest_node_version}"

  logging_service    = "${var.kubernetes_logging_service}"
  monitoring_service = "${var.kubernetes_monitoring_service}"

  initial_node_count = "${var.kubernetes_nodes_per_zone}"

  node_config {
    machine_type    = "${var.kubernetes_instance_type}"
    service_account = "${google_service_account.account.email}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    tags = ["atlantis", "terraform"]

    workload_metadata_config {
      node_metadata = "SECURE"
    }
  }

  addons_config {
    kubernetes_dashboard {
      disabled = true
    }

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
      start_time = "${var.kubernetes_daily_maintenance_window}"
    }
  }

  depends_on = [
    "google_project_service.service",
    "google_storage_bucket_iam_member.sa-to-bucket",
    "google_project_iam_member.service-account",
  ]
}

output "project" {
  value = "${google_project.project.project_id}"
}

output "region" {
  value = "${var.region}"
}

output "address" {
  value = "${google_compute_address.address.address}"
}
