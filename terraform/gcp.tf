provider "google" {
  region  = "${var.region}"
  zone    = "${var.zone}"
  project = "${var.project}"
}

resource "random_id" "random" {
  prefix      = "terraform-"
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

resource "google_container_cluster" "cluster" {
  name    = "terraform-atlantis"
  project = "${google_project.project.project_id}"
  zone    = "${var.zone}"

  min_master_version = "${var.kubernetes_version}"
  node_version       = "${var.kubernetes_version}"

  initial_node_count = "${var.num_servers}"

  node_config {
    machine_type    = "${var.instance_type}"
    service_account = "${google_service_account.account.email}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    tags = ["atlantis", "terraform"]
  }

  depends_on = ["google_project_service.service"]
}

resource "google_compute_address" "address" {
  name    = "load-balancer"
  region  = "${var.region}"
  project = "${google_project.project.project_id}"

  depends_on = ["google_project_service.service"]
}

resource "random_id" "encryption-key" {
  byte_length = "32"
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "${tls_private_key.ca.algorithm}"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  subject {
    common_name  = "ca.local"
    organization = "Atlantis"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]

  provisioner "local-exec" {
    command = "echo '${self.cert_pem}' > ../tls/ca.pem && chmod 0600 ../tls/ca.pem"
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = "2048"

  provisioner "local-exec" {
    command = "echo '${self.private_key_pem}' > ../tls/tls.key && chmod 0600 ../tls/tls.key"
  }
}

resource "tls_cert_request" "request" {
  key_algorithm   = "${tls_private_key.key.algorithm}"
  private_key_pem = "${tls_private_key.key.private_key_pem}"

  dns_names = [
    "atlantis",
    "atlantis.local",
    "atlantis.default.svc.cluster.local",
    "localhost",
  ]

  ip_addresses = [
    "127.0.0.1",
    "${google_compute_address.address.address}",
  ]

  subject {
    common_name  = "atlantis.local"
    organization = "Atlantis"
  }
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = "${tls_cert_request.request.cert_request_pem}"

  ca_key_algorithm   = "${tls_private_key.ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.ca.cert_pem}"

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]

  provisioner "local-exec" {
    command = "echo '${self.cert_pem}' > ../tls/tls.cert && echo '${tls_self_signed_cert.ca.cert_pem}' >> ../tls/tls.cert && chmod 0600 ../tls/tls.cert"
  }
}

output "project" {
  value = "${google_project.project.project_id}"
}

output "zone" {
  value = "${var.zone}"
}

output "region" {
  value = "${var.region}"
}

output "address" {
  value = "${google_compute_address.address.address}"
}
