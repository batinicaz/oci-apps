# Terraform Template

Template repository for Terraform projects using Infisical for secrets management.

## Features

- Automated dependency updates via Renovate
- Pre-commit hooks for code quality (terraform-fmt, tflint, terraform-validate, checkov)
- Automatic terraform-docs generation
- GitHub Actions CI/CD with plan on PR, apply on release tags
- Infisical integration for secure secrets management via OIDC

## Quick Start

When creating a new repository from this template:

1. **Configure Infisical GitHub App**
   - Add the new repository to your Infisical GitHub App integration
   - Secrets will sync automatically once the app has access

2. **Create Infisical Environment**
   - Create a new environment in your Infisical project: `terraform-<repo-name>`
   - Add your provider-specific secrets to this environment
   - The workflow will automatically use this environment based on the repo name

3. **Configure GitHub Repository Variable**
   - Add `INFISICAL_IDENTITY_ID` as a repository variable (Settings > Secrets and variables > Actions > Variables)
   - This is the OIDC identity ID for GitHub Actions authentication

4. **Configure Release Bot Secrets** (synced automatically via Infisical)
   - `APP_ID` - GitHub App ID for the release bot
   - `APP_PRIVATE_KEY` - Private key for the GitHub App

5. **Update Makefile for Local Development**
   - Edit `Makefile` line 2: replace `terraform-<REPO_NAME>` with `terraform-<your-repo-name>`
   - This matches your Infisical environment for local development

6. **Run Pre-commit Autoupdate**
   ```bash
   pre-commit autoupdate
   ```
   This ensures you have the latest versions of all hooks.

7. **Start Developing**
   - Add your Terraform configuration files
   - Configure your S3/R2 backend in `terraform.tf`
   - Update this README with your project-specific documentation

## Local Development

Use the provided Makefile for local development with Infisical secrets:

```bash
make init      # Initialize Terraform
make plan      # Run Terraform plan
make apply     # Apply changes
make destroy   # Destroy infrastructure
make fmt       # Format Terraform files
make validate  # Validate configuration
make console   # Open Terraform console
make lock      # Lock provider versions
```

Requires [Infisical CLI](https://infisical.com/docs/cli/overview) to be installed and authenticated.

## Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `feature.yml` | Push to non-main branches | Lint + Terraform plan |
| `main.yml` | Push to main | Create release |
| `release.yml` | Push v* tags | Terraform apply |
| `docs.yml` | Push to renovate/* branches | Auto-update terraform-docs |

## Pre-commit Hooks

Install pre-commit hooks locally:

```bash
pre-commit install
```

The following hooks are configured:
- **terraform-docs** - Auto-generates documentation from Terraform code
- **terraform-fmt** - Formats Terraform files
- **tflint** - Lints Terraform code
- **terraform-validate** - Validates Terraform configuration
- **checkov** - Security scanning for infrastructure as code

To add project-specific checkov skips, edit `.pre-commit-config.yaml`:
```yaml
- id: checkov
  args:
    - --skip-check=CKV_XXX # Reason for skipping
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
