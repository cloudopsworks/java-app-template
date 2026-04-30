# Java Application Template

This repository is a **CloudOps Works Java application template**. It gives you:

- a Maven-based Java application scaffold
- CloudOps Works CI/CD wiring under `.cloudopsworks/`
- GitHub Actions workflows for build, scan, preview, release, and deployment
- deployment templates for Kubernetes, Lambda, Elastic Beanstalk, App Engine, and Cloud Run

Use this template when you want a new Java service or library that already follows the CloudOps Works delivery model.

---

## What this template includes

### Application scaffold
- `pom.xml` — base Maven project definition with placeholder coordinates and CI-friendly plugins
- `src/main/java/` — placeholder for application source code
- `src/test/` — placeholder for test sources
- `apifiles/` — API definition placeholders
- `Makefile` — bootstrap and version helper targets

### Delivery scaffold
- `.cloudopsworks/cloudopsworks-ci.yaml` — repository governance and environment mapping
- `.cloudopsworks/vars/inputs-global.yaml` — global build/deploy defaults
- `.cloudopsworks/vars/inputs-*.yaml` — target-specific environment templates
- `.cloudopsworks/vars/apigw/` — API Gateway templates per environment
- `.cloudopsworks/vars/helm/` — Helm values per environment
- `.cloudopsworks/vars/preview/` — preview-environment defaults
- `.cloudopsworks/gitversion.yaml` — backward-compatible default GitVersion config for GitFlow-based generated repos
- `.cloudopsworks/gitversion_gitflow.yaml` — explicit GitFlow reference config
- `.cloudopsworks/gitversion_githubflow.yaml` — explicit GitHub Flow reference config
- `.github/workflows/` — reusable CI/CD orchestration

---

## Quick start

### 1. Create a repository from this template
Create your new repository from `cloudopsworks/java-app-template`, then clone it locally.

### 2. Bootstrap the Maven project metadata
From the root of the new repository, run:

```bash
make code/init
```

This target updates `pom.xml` to:
- set `artifactId` to the current directory name
- set the project version to the current GitVersion-derived `MajorMinorPatch-SNAPSHOT`

### 3. Replace the template placeholders in `pom.xml`
`make code/init` does **not** complete all Maven metadata. Review and replace these placeholders manually:

- `GROUP_ID`
- `ARTIFACT_ID`
- `VERSION`
- `NAME`
- `PACKAGE.MAIN.CLASS`
- `https://maven.pkg.github.com/ORG/REPO`

Also review whether the sample Spring Boot parent is correct for your service. The template intentionally leaves that decision open.

### 4. Add your application code
At minimum, create or replace:
- `src/main/java/...` with your package structure and entrypoint
- `src/test/java/...` with at least a smoke test
- `apifiles/` if the service publishes API definitions

This template ships with placeholders rather than a committed demo service, so your first application commit should establish the actual source layout.

### 5. Verify locally
```bash
mvn test
make version
```

`make version` writes a `VERSION` file using GitVersion semantics. On a tagged commit it uses the tag value; otherwise it derives the version from branch history and also updates the Maven project version.

---

## Required template configuration

### `.cloudopsworks/cloudopsworks-ci.yaml`
This file controls repository behavior and deployment routing.

Update these sections first:

#### `config`
- `branchProtection` — enable branch protection automation
- `gitFlow.enabled` — keep `true` if you use GitFlow branch conventions
- `gitFlow.supportBranches` — enable only if you maintain long-lived support branches
- `requiredReviewers`, `reviewers`, `owners`, `contributors` — repository governance

#### `cd.deployments`
This maps branch/tag flows to deployment environments.

Default mapping in this template:
- `develop` -> `dev`
- `release/**` -> `prod`
- internal `test` stage -> `uat`
- prerelease tags -> `demo`
- `hotfix` -> `hotfix`
- optional `support` mappings by version match

Adjust these names to match your environments and promotion flow.

### `.cloudopsworks/vars/inputs-global.yaml`
This is the main global configuration file used by the workflows.

Set these values before your first pipeline run:
- `organization_name`
- `organization_unit`
- `environment_name`
- `repository_owner`
- `cloud`
- `cloud_type`

Common optional sections:
- `java` — JDK version, distribution, and image variant
- `maven_options` — additional Maven flags
- `preview` — PR preview environment behavior
- `apis` — API Gateway publishing
- `observability` — tracing/monitoring agent configuration
- `snyk`, `semgrep`, `trivy`, `sonarqube`, `dependencyTrack` — security/quality tooling
- `docker_inline`, `docker_args`, `custom_run_command`, `custom_usergroup` — container customization
- `is_library` — library-only mode
- `api_files_dir` — custom path for API definitions

---

## Choose one deployment target per environment

Each active environment should have exactly one matching deployment-target file under `.cloudopsworks/vars/`.

### Kubernetes / EKS / AKS / GKE
Use `inputs-KUBERNETES-ENV.yaml`.

Key fields:
- `container_registry`
- `cluster_name`
- `namespace`
- target-cloud credentials/settings
- optional Helm, secret, and external-secret overrides

### AWS Lambda
Use `inputs-LAMBDA-ENV.yaml`.

Key fields:
- `versions_bucket`
- `aws.region`
- Lambda runtime/handler settings
- IAM, VPC, trigger, and concurrency configuration

### AWS Elastic Beanstalk
Use `inputs-BEANSTALK-ENV.yaml`.

Key fields:
- `versions_bucket`
- `container_registry`
- `aws.region`
- Beanstalk platform, instance, networking, and port mappings

### Google App Engine
Use `inputs-APPENGINE.yaml`.

Key fields:
- `container_registry`
- `gcp.region`
- `gcp.project_id`
- `appengine.runtime`
- `appengine.type`
- `appengine.entrypoint_shell`

### Google Cloud Run
Use `inputs-CLOUDRUN.yaml`.

Key fields:
- `container_registry`
- `gcp.region`
- `gcp.project_id`
- `cloudrun.type`

### Library / no-deploy mode
Use `inputs-LIB-ENV.yaml`.

Use this when the repository should publish artifacts but not deploy runtime infrastructure.

---

## Preview environments

Preview environments are configured from:
- `.cloudopsworks/vars/preview/inputs.yaml`
- `.cloudopsworks/vars/preview/values.yaml`

Enable them in `inputs-global.yaml`:

```yaml
preview:
  enabled: true
```

Use preview environments when pull requests from `feature/**` or `hotfix/**` should deploy an isolated review environment.

---

## API Gateway configuration

If the service publishes APIs, configure:
- `.cloudopsworks/vars/apigw/apis-global.yaml`
- `.cloudopsworks/vars/apigw/apis-dev.yaml`
- `.cloudopsworks/vars/apigw/apis-uat.yaml`
- `.cloudopsworks/vars/apigw/apis-prod.yaml`

Enable API deployment in `inputs-global.yaml`:

```yaml
apis:
  enabled: true
```

API definitions are read from `apifiles/` unless `api_files_dir` overrides that path.

---

## Helm values overrides

For Kubernetes targets, environment-specific Helm overrides live in:
- `.cloudopsworks/vars/helm/values-dev.yaml`
- `.cloudopsworks/vars/helm/values-uat.yaml`
- `.cloudopsworks/vars/helm/values-prod.yaml`

Use them to override ingress, probes, resources, autoscaling, environment variables, and other chart-level behavior without editing the blueprint chart itself.

---

## GitHub Actions workflow model

Important workflows in this template:

- `main-build.yml` — build, test, containerize, scan, and release/deploy on branch/tag events
- `pr-build.yml` — PR validation and optional preview deployment
- `deploy-container.yml` — push application container artifacts
- `deploy.yml` — standard deployment flow
- `deploy-blue-green.yml` — blue/green deployment flow
- `scan.yml` — SAST/SCA orchestration
- `environment-unlock.yml` / `environment-destroy.yml` — environment operations
- `automerge.yml`, `process-owners.yml`, Jira integration workflows, and slash-command workflows — repo automation
- `pr-close.yaml` — post-merge/tag cleanup actions

This template no longer includes `patch-management.yml`.

This template also ships dedicated GitVersion reference files for both GitFlow and GitHub Flow release models. If your generated repository wants to use one of them directly, wire it explicitly in your generator or build logic rather than assuming automatic selection.

---

## Secrets and variables expected by workflows

The workflows expect GitHub repository or organization configuration for build, preview, and deploy credentials.

Typical examples:
- `BOT_TOKEN`
- `BUILD_AWS_ACCESS_KEY_ID` / `BUILD_AWS_SECRET_ACCESS_KEY`
- `DEPLOYMENT_AWS_ACCESS_KEY_ID` / `DEPLOYMENT_AWS_SECRET_ACCESS_KEY`
- `BUILD_GCP_CREDENTIALS` / `DEPLOYMENT_GCP_CREDENTIALS`
- `BUILD_AZURE_SERVICE_ID` / `BUILD_AZURE_SERVICE_SECRET`
- `DEPLOYMENT_AZURE_SERVICE_ID` / `DEPLOYMENT_AZURE_SERVICE_SECRET`
- runner, registry, region, and state configuration variables

Review the `with:` and `secrets:` blocks in the workflow files and align your repository settings before enabling deployments.

---

## Release and versioning expectations

This template repository follows semantic versioning.

- documentation/template-only fixes -> patch release
- backward-compatible template capability additions -> minor release
- breaking workflow or template contract changes -> major release

Version calculation is GitVersion-based, and release automation relies on commit/PR annotations such as:
- `+semver: patch`
- `+semver: fix`
- `+semver: minor`
- `+semver: feature`
- `+semver: major`

For template consumers:
- `.cloudopsworks/gitversion.yaml` remains the compatibility default for GitFlow repositories
- `.cloudopsworks/gitversion_gitflow.yaml` is the explicit GitFlow reference
- `.cloudopsworks/gitversion_githubflow.yaml` is the explicit GitHub Flow reference

If you use the CloudOps Works release workflow, keep changes grouped by release intent so the generated version bump stays predictable.

---

## Recommended first-pass checklist for new repositories

- [ ] Create repo from template
- [ ] Run `make code/init`
- [ ] Replace the `pom.xml` placeholders and choose your final parent/dependencies
- [ ] Add real application sources under `src/main/java`
- [ ] Add at least one test under `src/test/java`
- [ ] Update `.cloudopsworks/cloudopsworks-ci.yaml`
- [ ] Update `.cloudopsworks/vars/inputs-global.yaml`
- [ ] Configure exactly one target file per active environment
- [ ] Configure preview settings if needed
- [ ] Configure API Gateway files if needed
- [ ] Add required GitHub secrets and variables
- [ ] Run `mvn test`
- [ ] Open a PR and verify `pr-build.yml`
- [ ] Merge and verify the first environment deployment

---

## Notes

- `.omx/`, `.omc/`, `.claude/`, `.opencode/`, and similar agent/tooling directories are intentionally ignored and are not part of the application template contract.
- The template is designed for CloudOps Works blueprint-backed automation; if you remove that integration, also prune the related workflows and `.cloudopsworks/` configuration.
