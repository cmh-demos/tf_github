locals {
  # Read GitHub credentials from file 'github_creds' in module directory.
  # File contains JSON with keys: github_token and github_owner
  github_creds = jsondecode(file("${path.module}/github_creds"))

  # Read the list of repo names we want to check
  github_repos = jsondecode(file("${path.module}/github_repos.json"))
}

provider "github" {
  token = local.github_creds.github_token
  owner = local.github_creds.github_owner
}

# Use the HTTP data source to safely check repository existence via the
# GitHub REST API. It won't fail the plan on 404 — we just read the status
# and return evidence of existence.
data "http" "repo_check" {
  for_each = toset(local.github_repos)

  url = "https://api.github.com/repos/${local.github_creds.github_owner}/${each.value}"

  request_headers = {
    Authorization = "token ${local.github_creds.github_token}"
    Accept        = "application/vnd.github.v3+json"
  }
}

locals {
  repo_exists = {
    for repo, resp in data.http.repo_check : repo => (try(resp.status_code, 0) == 200)
  }
}

# Build a map of repos that do not exist yet (key=repo name, value=repo name)
locals {
  repos_to_create = {
    for r, exists in local.repo_exists : r => r
    if !exists
  }
}

output "repo_exists_map" {
  description = "Map of repository name -> boolean indicating whether the repository exists for the given owner"
  value       = local.repo_exists
}

resource "github_repository" "create_missing" {
  for_each = local.repos_to_create

  name      = each.key
  description = "Created by Terraform: tf_github scaffold"
  # `private` is deprecated; use `visibility` instead. Set to "public" or "private".
  visibility = "public"
  auto_init = true

  # provider owner is set with the provider block; resources will be created
  # for the organization/owner provided in github_creds
}

output "created_repos" {
  description = "List of repository names Terraform will create (empty if none)."
  value       = keys(github_repository.create_missing)
}
