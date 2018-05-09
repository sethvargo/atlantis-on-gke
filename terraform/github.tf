provider "github" {
  token        = "${var.github_token}"
  organization = "${var.github_organization}"
}

resource "random_id" "webhook" {
  byte_length = "64"
}

resource "github_repository" "repo" {
  name         = "${random_id.random.hex}"
  description  = "Terraform Atlantis Demo"
  homepage_url = "https://www.runatlantis.io/"

  private       = false
  has_issues    = false
  has_wiki      = false
  has_downloads = false

  allow_merge_commit = false
  allow_squash_merge = false
  allow_rebase_merge = true
}

resource "github_repository_webhook" "hook" {
  name       = "web"
  repository = "${github_repository.repo.name}"

  configuration {
    url          = "https://${google_compute_address.address.address}/events"
    content_type = "application/json"
    insecure_ssl = true
    secret       = "${random_id.webhook.hex}"
  }

  events = [
    "issue_comment",
    "pull_request",
    "pull_request_review",
    "pull_request_review_comment",
  ]

  lifecycle {
    # The secret is saved as ******* in the state
    ignore_changes = ["configuration.secret"]
  }
}

output "repository" {
  value = "${github_repository.repo.http_clone_url}"
}
