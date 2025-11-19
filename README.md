# tf_github

Terraform scaffold to check if specified GitHub repositories exist for a user/organization.

How it works
- `github_creds` — local JSON file with `github_token` and `github_owner`.
- `github_repos.json` — list of repo names (array of strings) to check for existence.
- Terraform reads both files using `file()` and `jsondecode()` then queries the GitHub API
  using the `http` data source for each repo to check HTTP status (200 -> exists).

Files
- `versions.tf`: provider configuration
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