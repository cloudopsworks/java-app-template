# Java Application Template

This repository is the **CloudOps Works Java application template** for bootstrapping a new Java service or library with Maven, GitHub Actions, and CloudOps Works delivery wiring already in place.

Use this template when you want a repository that already includes:

- a Maven project skeleton
- CloudOps Works CI/CD configuration under `.cloudopsworks/`
- GitHub Actions workflows for PR validation, build, scan, release, and deploy
- deployment templates for Kubernetes, Lambda, Elastic Beanstalk, App Engine, Cloud Run, or library-only publishing

---

## What gets generated from this template

### Application scaffold
- `pom.xml` — base Maven definition with placeholder coordinates and a sample Spring Boot parent
- `src/main/java/.placeholder` — placeholder for application sources
- `src/test/.placeholder` — placeholder for tests
- `apifiles/` — API definition placeholders
- `Makefile` — bootstrap and GitVersion-backed version helper targets

### Delivery scaffold
- `.cloudopsworks/cloudopsworks-ci.yaml` — repository governance and deployment routing
- `.cloudopsworks/vars/inputs-global.yaml` — global build/deploy defaults
- `.cloudopsworks/vars/inputs-*.yaml` — deployment-target templates
- `.cloudopsworks/vars/preview/` — preview-environment defaults when enabled
- `.cloudopsworks/vars/apigw/` — API Gateway templates when APIs are published
- `.cloudopsworks/gitversion.yaml` — compatibility/default GitFlow config for generated repositories
- `.cloudopsworks/gitversion_gitflow.yaml` — explicit GitFlow reference configuration
- `.cloudopsworks/gitversion_githubflow.yaml` — explicit GitHub Flow reference configuration
- `.github/workflows/` — reusable CI/CD orchestration

---

## Recommended bootstrap flow

### 1. Create a repository from this template
Create a new repository from `cloudopsworks/java-app-template`, then clone it locally.

### 2. Initialize the Maven metadata
From the root of the generated repository, run:

```bash
make code/init
```

This target updates `pom.xml` to:
- set `artifactId` to the current directory name
- set the project version to `MajorMinorPatch-SNAPSHOT` derived from GitVersion

### 3. Replace the placeholder metadata in `pom.xml`
`make code/init` does not finish the Java project definition for you. Review and replace at least:

- `GROUP_ID`
- `ARTIFACT_ID`
- `VERSION`
- `NAME`
- `PACKAGE.MAIN.CLASS`
- `https://maven.pkg.github.com/ORG/REPO`

Also decide whether the sample Spring Boot parent and starter dependencies are appropriate for your project. The template intentionally keeps those as examples, not mandatory choices.

### 4. Create the real source layout
Replace the placeholder files with real code and tests:

- create your package structure under `src/main/java/`
- add tests under `src/test/java/`
- add or remove `apifiles/` depending on whether the service publishes API definitions

### 5. Verify the repository locally
```bash
mvn test
make version
```

`make version` writes a `VERSION` file and updates the Maven project version using GitVersion semantics.

---

## Template customization guide

### `pom.xml`
Review the generated Maven project before the first PR:

- choose the final `groupId`, `artifactId`, `name`, and `description`
- choose whether to keep Spring Boot as the parent
- set the correct Java version and main class
- keep or replace the example dependencies
- update `distributionManagement` if the package should publish somewhere other than GitHub Packages

### `README.md`
Replace the minimal template placeholder with repository-specific documentation:

- what the service or library does
- how to build and test it
- runtime or deployment assumptions
- required environment variables or credentials
- API or operational references

### `.cloudopsworks/cloudopsworks-ci.yaml`
This file controls repository governance and deployment routing.

Update these sections first:

#### `config`
- `branchProtection` — enable/disable branch protection automation
- `gitFlow.enabled` — keep `true` when using GitFlow branch conventions
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

Adjust the environment names and routing rules to match your promotion model.

### `.cloudopsworks/vars/inputs-global.yaml`
This is the main global configuration file used by the workflows.

Set these values before the first pipeline run:
- `organization_name`
- `organization_unit`
- `environment_name`
- `repository_owner`
- `cloud`
- `cloud_type`

Common optional sections:
- `java` — JDK version, distribution, image variant
- `maven_options` — extra Maven flags
- `preview` — PR preview configuration
- `apis` — API Gateway deployment toggle
- `observability` — tracing/monitoring agent configuration
- `snyk`, `semgrep`, `trivy`, `sonarqube`, `dependencyTrack` — security and quality tooling
- `docker_inline`, `docker_args`, `custom_run_command`, `custom_usergroup` — container customization
- `is_library` — artifact-only mode
- `api_files_dir` — custom path for API definitions

---

## Choose a deployment target

Each active environment should use exactly one matching deployment-target file under `.cloudopsworks/vars/`.

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
Use `inputs-LIB-ENV.yaml` when the repository should publish artifacts but not deploy runtime infrastructure.

---

## Optional features

### Preview environments
Preview environments are configured from:
- `.cloudopsworks/vars/preview/inputs.yaml`
- `.cloudopsworks/vars/preview/values.yaml`

Enable them in `inputs-global.yaml`:

```yaml
preview:
  enabled: true
```

Use preview environments when pull requests from `feature/**` or `hotfix/**` should deploy isolated review environments.

### API Gateway publication
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

API definitions are read from `apifiles/` unless `api_files_dir` overrides the path.

### Helm values overrides
For Kubernetes targets, environment-specific Helm overrides live in:
- `.cloudopsworks/vars/helm/values-dev.yaml`
- `.cloudopsworks/vars/helm/values-uat.yaml`
- `.cloudopsworks/vars/helm/values-prod.yaml`

Use them to override ingress, probes, resources, autoscaling, environment variables, and other chart-level behavior without editing the blueprint chart.

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
- `automerge.yml`, `process-owners.yml`, Jira integration workflows, and slash-command workflows — repository automation
- `pr-close.yaml` — post-merge/tag cleanup actions

This template no longer includes `patch-management.yml`.

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

Version calculation is GitVersion-based, and release automation relies on commit and PR body annotations such as:
- `+semver: patch`
- `+semver: fix`
- `+semver: minor`
- `+semver: feature`
- `+semver: major`

This template ships three GitVersion-related files:
- `.cloudopsworks/gitversion.yaml` — compatibility/default GitFlow config for generated repositories
- `.cloudopsworks/gitversion_gitflow.yaml` — explicit GitFlow reference file
- `.cloudopsworks/gitversion_githubflow.yaml` — explicit GitHub Flow reference file

Use the explicit reference files when your generator or bootstrap logic wants to select a flow intentionally. Keep `gitversion.yaml` when you want the generated repository to retain the default GitFlow-compatible filename expected by older automation.

If you use the CloudOps Works release workflow, keep changes grouped by release intent so the generated version bump stays predictable.

---

## Recommended first-pass checklist for generated repositories

- [ ] Create the repo from this template
- [ ] Run `make code/init`
- [ ] Replace the `pom.xml` placeholders and choose the final parent/dependencies
- [ ] Replace `README.md` with project-specific documentation
- [ ] Add real application sources under `src/main/java`
- [ ] Add at least one test under `src/test/java`
- [ ] Update `.cloudopsworks/cloudopsworks-ci.yaml`
- [ ] Update `.cloudopsworks/vars/inputs-global.yaml`
- [ ] Configure exactly one deployment target file per active environment
- [ ] Configure preview settings if needed
- [ ] Configure API Gateway files if needed
- [ ] Add the required GitHub secrets and variables
- [ ] Run `mvn test`
- [ ] Run `make version`
- [ ] Open a PR and verify `pr-build.yml`
- [ ] Merge and verify the first environment deployment or artifact publication

---

## Notes

- `.omx/`, `.omc/`, `.claude/`, `.opencode/`, and similar agent/tooling directories are intentionally ignored and are not part of the application template contract.
- The template is designed for CloudOps Works blueprint-backed automation; if you remove that integration, also prune the related workflows and `.cloudopsworks/` configuration.
