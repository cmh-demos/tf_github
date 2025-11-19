# tf_github

Terraform scaffold to check if specified GitHub repositories exist for a user/organization.

How it works
- `github_creds` — local JSON file with `github_token` and `github_owner`.
- `github_repos.json` — list of repo names (array of strings) to check for existence.
- Terraform reads both files using `file()` and `jsondecode()` then queries the GitHub API
  using the `http` data source for each repo to check HTTP status (200 -> exists).

Files
- `versions.tf`: provider configuration
  - `hashicorp/http`: required provider used to probe GitHub API endpoints (added to `versions.tf`)
- `main.tf`: logic to load creds, check repos, and export results
- `github_repos.json`: sample list of repositories to check
- `github_creds.sample`: sample credentials; copy to `github_creds` and fill with your details

Usage
1. Copy sample creds:
```
cp github_creds.sample github_creds
# Edit the file and add your token and owner
```

2. Initialize Terraform and run plan:
```
terraform init
terraform plan
```

3. See `repo_exists_map` in the plan output. You can decode `jsondecode` if needed.

Repo init & push (automated)
- This scaffold can be pushed to GitHub with the provided `github_creds` token. If the remote
  repository `tf_github` does not exist it will be created under the configured owner and the
  scaffold will be pushed as an initial commit. To push locally run the following commands:

```
# Create the repo on GitHub and push the code
cd tf_github
# Make sure github_creds is present and contains a token with repo creation privileges
bash -c "token=$(python3 -c 'import json,sys;print(json.load(open("github_creds"))["github_token"])'); owner=$(python3 -c 'import json,sys;print(json.load(open("github_creds"))["github_owner"])'); repo=tf_github;\
curl -H \"Authorization: token $token\" https://api.github.com/repos/$owner/$repo -s -o /dev/null || curl -X POST -H \"Authorization: token $token\" -d '{\"name\":\"'$repo'\",\"private\":false}' https://api.github.com/user/repos;\
git remote add origin https://github.com/$owner/$repo.git || true; git push https://$token@github.com/$owner/$repo.git main -u; git remote set-url origin https://github.com/$owner/$repo.git"
```

Create missing repositories
- When you run `terraform apply`, any repositories that did not exist will be created by the
  `github_repository.create_missing` resource. Created repositories are initialized with a README
  (via `auto_init = true`) and are public by default. Update `main.tf` to change `private` or
  other settings if you want different defaults.

Visibility note
- Starting with recent versions of the `github` provider, `private` is deprecated; use
  `visibility = "public" | "private"` instead. To change visibility, edit `main.tf` and
  update the `visibility` argument on the `github_repository.create_missing` resource or add a
  variable and map per-repo settings in `github_repos.json`.

Running apply:
```
terraform apply
```

Notes
- The `http` data source checks the GitHub API endpoint and will return the status code.
- If you want to use the `github` provider data sources instead, note those can error when a repo
  does not exist — using `http` keeps the plan from failing when a repo is missing.

CI / Security scanning
- This repository includes a GitHub Actions workflow `.github/workflows/security-scan.yml` that runs
  a set of security checks on pushes and pull requests:
  - Trivy `aquasecurity/trivy-action@0.33.1` — scans the filesystem and IaC (Terraform) for CVEs and
    misconfigurations.
  - tflint (`terraform-linters/setup-tflint@v6`) — Terraform linter for best practices and security rules.
  - Checkov `bridgecrew/checkov` — IaC static analysis to catch security policy violations.
  - Gitleaks `gitleaks/gitleaks-action@v2.3.9` — scans for secrets and credentials accidentally left in
    the repository.

Run locally
- Trivy (local scan): `trivy fs .` or `trivy config tf_github` to scan Terraform
 - After adding or changing providers, run `terraform init` to install or upgrade providers, e.g., `terraform init -upgrade`.
- Checkov: `pip install checkov` then `checkov -d tf_github`
- tflint: `brew install tflint` (macOS) or follow project instructions, then `tflint` in the
  `tf_github/` directory
