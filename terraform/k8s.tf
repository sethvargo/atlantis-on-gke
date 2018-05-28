provider "kubernetes" {
  host     = "${google_container_cluster.cluster.endpoint}"
  username = "${google_container_cluster.cluster.master_auth.0.username}"
  password = "${google_container_cluster.cluster.master_auth.0.password}"

  client_certificate     = "${base64decode(google_container_cluster.cluster.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.cluster.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_secret" "tls" {
  metadata {
    name = "tls"
  }

  data {
    "tls.crt" = "${tls_locally_signed_cert.cert.cert_pem}"
    "tls.key" = "${tls_private_key.key.private_key_pem}"
  }
}

resource "kubernetes_pod" "pod" {
  metadata {
    name = "atlantis"

    labels {
      app = "atlantis"
    }
  }

  spec {
    volume {
      name = "tls"

      secret {
        secret_name = "tls"
      }
    }

    container {
      name  = "atlantis"
      image = "runatlantis/atlantis:${var.atlantis_version}"
      args  = ["server"]

      port {
        name           = "atlantis"
        container_port = "4141"
        protocol       = "TCP"
      }

      env {
        name  = "ATLANTIS_LOG_LEVEL"
        value = "debug"
      }

      env {
        name  = "ATLANTIS_PORT"
        value = "4141"
      }

      env {
        name  = "ATLANTIS_ATLANTIS_URL"
        value = "https://${google_compute_address.address.address}"
      }

      env {
        name  = "ATLANTIS_GH_USER"
        value = "${var.atlantis_github_user}"
      }

      env {
        name  = "ATLANTIS_GH_TOKEN"
        value = "${var.atlantis_github_user_token}"
      }

      env {
        name  = "ATLANTIS_GH_WEBHOOK_SECRET"
        value = "${random_id.webhook.hex}"
      }

      env {
        name  = "ATLANTIS_REPO_WHITELIST"
        value = "${var.atlantis_repo_whitelist}"
      }

      env {
        name  = "ATLANTIS_SSL_CERT_FILE"
        value = "/etc/atlantis/tls/tls.crt"
      }

      env {
        name  = "ATLANTIS_SSL_KEY_FILE"
        value = "/etc/atlantis/tls/tls.key"
      }

      env {
        name  = "GOOGLE_ENCRYPTION_KEY"
        value = "${random_id.encryption-key.b64_std}"
      }

      env {
        name  = "GOOGLE_PROJECT"
        value = "${google_project.project.name}"
      }

      resources {
        requests {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      volume_mount {
        name       = "tls"
        mount_path = "/etc/atlantis/tls"
        read_only  = true
      }

      readiness_probe {
        initial_delay_seconds = "5"
        period_seconds        = "10"
        timeout_seconds       = "5"

        http_get {
          path   = "/"
          port   = "4141"
          scheme = "HTTPS"
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = "atlantis"
  }

  spec {
    type = "LoadBalancer"

    load_balancer_ip = "${google_compute_address.address.address}"

    selector {
      app = "${kubernetes_pod.pod.metadata.0.labels.app}"
    }

    port {
      name        = "atlantis-port"
      port        = "443"
      target_port = "4141"
      protocol    = "TCP"
    }
  }
}

output "url" {
  value = "https://${google_compute_address.address.address}"
}
