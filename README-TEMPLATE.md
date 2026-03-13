# Java Application Template - Complete Configuration Guide

## Table of Contents

- [Overview](#overview)
- [Blueprint Architecture](#blueprint-architecture)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Module Configuration (.cloudopsworks/vars)](#module-configuration-cloudopsworksvars)
  - [inputs-global.yaml](#inputs-globalyaml)
  - [inputs-BEANSTALK-ENV.yaml](#inputs-beanstalk-envyaml)
  - [inputs-KUBERNETES-ENV.yaml](#inputs-kubernetes-envyaml)
  - [inputs-LAMBDA-ENV.yaml](#inputs-lambda-envyaml)
  - [inputs-CLOUDRUN.yaml](#inputs-cloudrunyaml)
  - [inputs-APPENGINE.yaml](#inputs-appengineyaml)
  - [inputs-LIB-ENV.yaml](#inputs-lib-envyaml)
- [CloudOpsWorks CI Configuration](#cloudopscworks-ci-configuration)
- [API Gateway Configuration](#api-gateway-configuration)
- [Helm Chart Configuration](#helm-chart-configuration)
- [Preview Environment Configuration](#preview-environment-configuration)
- [Deployment Targets](#deployment-targets)

---

## Overview

This Java application template is part of the Cloud Ops Works automation framework, leveraging the [blueprints repository](https://github.com/cloudopsworks/blueprints) to provide comprehensive CI/CD capabilities for Java applications across multiple cloud providers (AWS, Azure, GCP) and deployment targets.

The template supports:
- **Multiple Cloud Providers**: AWS, Azure, Google Cloud Platform
- **Multiple Deployment Targets**: 
  - AWS: Elastic Beanstalk, EKS, Lambda
  - Azure: AKS, Web App, Functions
  - GCP: GKE, App Engine, Cloud Run
- **GitFlow Workflow**: Automated deployments based on branch strategy
- **Preview Environments**: Temporary environments for Pull Requests
- **Security Scanning**: Snyk, Semgrep, SonarQube, Dependency Track
- **API Gateway Management**: Automated API deployment and management
- **Observability**: X-Ray, New Relic, DataDog, Dynatrace integration

---

## Blueprint Architecture

The template uses GitHub Actions that reference the Cloud Ops Works blueprints repository using the `./bp` prefix. All actions are versioned and referenced from `cloudopsworks/blueprints@v5.10`.

### Blueprint Action Categories

#### CI Actions (`./bp/ci/*`)
- **Configuration & Setup**
  - `./bp/ci/config` - Retrieves pipeline configuration from .cloudopsworks/vars
  - `./bp/ci/common/install/runner-tools` - Installs required tools on runner
  - `./bp/ci/common/download/artifacts` - Downloads build artifacts

- **Java Build Actions**
  - `./bp/ci/java/build` - Builds Java application with Maven
  - `./bp/ci/java/deploy` - Deploys Java libraries to Maven repository
  - `./bp/ci/java/artifacts` - Saves build artifacts
  - `./bp/ci/java/container` - Builds and pushes Docker container

- **API Actions**
  - `./bp/ci/api/artifacts` - Saves API definition artifacts
  - `./bp/ci/api/scan/sonarqube` - Scans API definitions with SonarQube

- **Scanning Actions**
  - `./bp/ci/scan/config` - Configures security scanning
  - `./bp/ci/java/scan/semgrep` - Semgrep SAST scanning
  - `./bp/ci/java/scan/snyk` - Snyk SCA/SAST scanning
  - `./bp/ci/java/scan/sonarqube` - SonarQube code quality
  - `./bp/ci/scan/sonarqube/quality-gate` - SonarQube quality gate check
  - `./bp/ci/java/scan/dtrack` - Dependency Track SCA scanning

#### CD Actions (`./bp/cd/*`)
- **Deployment Actions**
  - `./bp/cd/checkout` - Checkout with blueprint support
  - `./bp/cd/deploy/app/aws` - Deploy application to AWS
  - `./bp/cd/deploy/app/azure` - Deploy application to Azure
  - `./bp/cd/deploy/app/gcp` - Deploy application to GCP
  - `./bp/cd/deploy/api/aws` - Deploy API Gateway to AWS
  - `./bp/cd/deploy/api/azure` - Deploy API Management to Azure
  - `./bp/cd/deploy/api/gcp` - Deploy API Gateway to GCP
  - `./bp/cd/deploy/container` - Deploy container to registry
  - `./bp/cd/deploy/preview/aws` - Deploy preview environment to AWS
  - `./bp/cd/deploy/preview/azure` - Deploy preview environment to Azure
  - `./bp/cd/deploy/preview/gcp` - Deploy preview environment to GCP

- **Release & Tasks**
  - `./bp/cd/release` - Creates GitHub release
  - `./bp/cd/tasks/apis/copy` - Copies API definitions
  - `./bp/cd/tasks/repo/checkpr` - Validates pull requests

---

## GitHub Actions Workflows

### Core Workflows

#### 1. **main-build.yml** - Release Build Pipeline
**Trigger**: Push to `develop`, `support/**`, `release/**`, tags `v*.*.*`
**Purpose**: Main build and deployment pipeline following GitFlow

**Jobs**:
- `code-build`: Builds Java application, runs tests, creates artifacts
- `deploy-container`: Pushes container to registry
- `release`: Creates GitHub release (for production tags)
- `scan`: Security scanning (Snyk, Semgrep, SonarQube, Dependency Track)
- `deploy`: Deploys to target environment
- `deploy-blue-green`: Blue/green deployment for zero-downtime

**GitFlow Deployment Matrix**:
| Branch/Tag | Environment | Description |
|------------|-------------|-------------|
| `develop` | develop | Development environment |
| `release/**` | test | Testing/UAT environment |
| TAG on `release/**` (v*.*.*-alpha/beta.*) | prerelease | Pre-release with qualifiers |
| TAG on `main/master` (v*.*.*) | release | Production release |
| TAG on `support/**` | support | Support branch deployment |

#### 2. **pr-build.yml** - Pull Request Build
**Trigger**: Pull requests from `hotfix/**`, `feature/**` to any main branch
**Purpose**: Build, test, and create preview environments for PRs

**Jobs**:
- `check-pr`: Validates PR requirements
- `code-build`: Builds and tests the PR code
- `deploy-container`: Pushes PR container with tag
- `preview`: Creates temporary preview environment
- `scan`: Security scanning for PR

#### 3. **deploy.yml** - Single Environment Deployment
**Type**: Reusable workflow
**Purpose**: Deploys application and APIs to a single target environment

**Inputs**:
- `deployment_name`: Target environment name
- `cloud`: Cloud provider (AWS|AZURE|GCP)
- `cloud_type`: Deployment type (eks|beanstalk|lambda|aks|gke|etc.)
- `runner_set`: GitHub runner to use
- `semver`: Version to deploy
- `apis_enabled`: Deploy API Gateway configurations
- `observability_enabled`: Enable observability agents
- `observability_agent`: Agent type (xray|newrelic|datadog|dynatrace)

#### 4. **deploy-blue-green.yml** - Blue/Green Deployment
**Type**: Reusable workflow
**Purpose**: Zero-downtime deployments using blue/green strategy

**Process**:
1. Deploy to green environment
2. Deploy to blue environment (active)
3. Deploy APIs
4. Destroy green environment

**Use Case**: Production environments requiring zero downtime

#### 5. **deploy-container.yml** - Container Registry Deployment
**Type**: Reusable workflow
**Purpose**: Pushes built containers to cloud container registries

**Supported Registries**:
- AWS: ECR (Elastic Container Registry)
- Azure: ACR (Azure Container Registry)
- GCP: GCR/Artifact Registry

#### 6. **scan.yml** - Security Scanning
**Type**: Reusable workflow
**Purpose**: Comprehensive security scanning pipeline

**Scanning Tools**:
- **Semgrep**: Static Application Security Testing (SAST)
- **Snyk**: Software Composition Analysis (SCA)
- **SonarQube**: Code quality and security
- **Dependency Track**: SBOM and vulnerability tracking

**Features**:
- Quality gate enforcement (configurable)
- API definition scanning
- Test result upload
- Preview environment support

#### 7. **environment-destroy.yml** - Environment Destruction
**Trigger**: Manual workflow dispatch
**Purpose**: Destroy infrastructure for specific environments

**Options**:
- Target: `app`, `api`, or `BOTH`
- Qualifier: For blue/green deployments (green/blue)
- Environment: Select from configured environments

#### 8. **environment-unlock.yml** - Environment Unlock
**Purpose**: Removes deployment locks from environments

#### 9. **automerge.yml** - Auto-Merge
**Purpose**: Automatically merges approved PRs meeting criteria

#### 10. **slash-commands.yml** - Slash Commands
**Purpose**: Enables slash command interactions in PRs

#### 11. **jira-integration.yml** - JIRA Integration
**Purpose**: Integrates with JIRA for release management

#### 12. **patch-management.yml** - AI Patch Management
**Purpose**: Automated dependency updates using AI

#### 13. **process-owners.yml** - Process Owners
**Purpose**: Manages code owners and review assignments

---

## Module Configuration (.cloudopsworks/vars)

The `.cloudopsworks/vars` directory contains all environment-specific configurations. Each file serves a specific purpose in the deployment pipeline.

### inputs-global.yaml

**Purpose**: Base configuration file used across ALL environments. Contains global settings, feature toggles, and common configurations.

#### Organization & Repository Settings

```yaml
organization_name: "ORG_NAME"           # Organization name for tagging and identification
organization_unit: "ORG_UNIT"           # Business unit or department
environment_name: "ENV_NAME"            # Default environment name
repository_owner: "REPO_OWNER"          # Required: Repository owner for permissions
```

#### Java Build Configuration

```yaml
java:
  version: 25              # Java version (default: 25). Options: 17, 21, 25
  dist: temurin            # JDK distribution (default: temurin). Options: temurin, openjdk, zulu
  image_variant: alpine    # Docker image variant (default: alpine). Options: alpine, ubuntu, debian
```

**Notes**:
- Default Java version is 25 if not specified
- Temurin is the default distribution (Eclipse Adoptium)
- Alpine variant produces smaller container images

#### Security Scanning Configuration

**Snyk** (Disabled by default):
```yaml
snyk:
  enabled: true            # Enable Snyk SCA/SAST scanning
```

**Semgrep** (Disabled by default):
```yaml
semgrep:
  enabled: true            # Enable Semgrep SAST scanning
```

**SonarQube** (Disabled by default):
```yaml
sonarqube:
  enabled: true                      # Enable SonarQube analysis
  fail_on_quality_gate: true         # Fail pipeline on quality gate failure
  quality_gate_enabled: true         # Enable quality gate check (default: true)
  sources_path: "src/"               # Source code path
  binaries_path: "target/classes"    # Compiled classes path
  libraries_path: "target/libs/**/*.jar"  # Dependency JARs
  tests_path: "src/"                 # Test source path
  tests_binaries: "target/test-classes"  # Test compiled classes
  tests_inclusions: "src/**/test/**/*"   # Test file patterns
  tests_libraries: "target/libs/**/*.jar" # Test dependencies
  exclusions: "target/**,src/**/test/**/*" # Files to exclude
  extra_exclusions: []               # Additional exclusion patterns
  branch_disabled: true              # Set to true for SonarQube Community Edition
```

**Dependency Track** (Enabled by default):
```yaml
dependencyTrack:
  enabled: true          # Enable Dependency Track SBOM analysis
  type: Application      # Project type: Library, Application, Container, Framework, Device, Firmware, File, Operating System
```

#### JIRA Integration

```yaml
jira:
  enabled: true                    # Enable JIRA integration (default: true)
  project_id: "12345"              # JIRA project ID (optional, falls back to org setting)
  project_key: "PROJECTKEY"        # JIRA project key (optional, falls back to org setting)
```

**Notes**:
- Requires `JIRA_INTEGRATION_ENABLED` at organization level
- Used for release management and commit filtering
- Automatically links commits to JIRA issues

#### Library Project Configuration

```yaml
is_library: true    # Mark project as library (deprecated: was isLibrary)
```

**Notes**:
- When enabled, deploys to Maven repository instead of container
- Skips container build process
- Enables library-specific deployment workflow

#### Docker Configuration

**Inline Dockerfile Content**:
```yaml
docker_inline: |
  # Custom Dockerfile instructions
  WORKDIR /app
  COPY package*.json ./
  COPY ./mydir ./my dest
```

**Docker Build Arguments**:
```yaml
docker_args: |
  ARG1=value1
  ARG2=value2
  ARG3=value3
```

**Custom Run Command**:
```yaml
custom_run_command: java -jar app.jar
```

**Custom User/Group Creation** (for Busybox, RHEL UBI, Fedora):
```yaml
custom_usergroup: |
  groupadd --gid $GROUP_ID --system $GROUP_NAME \
    && useradd --uid $USER_ID --system --gid $GROUP_ID --home /app/webapp $USER_NAME
```

#### Maven Configuration

```yaml
maven_options: "-T 1C -Dmaven.wagon.http.retryHandler.count=3"
```

**Notes**:
- `-T 1C`: Threaded build (one thread per core)
- Retry handler for unreliable networks

#### API Gateway Configuration

```yaml
api_files_dir: "apifiles"    # Custom path for API definitions (default: ./apifiles)

apis:
  enabled: true              # Enable API Gateway deployment
```

**Notes**:
- API definitions stored in `apifiles/` directory by default
- Supports AWS API Gateway, Azure API Management, GCP API Gateway

#### Preview Environment Configuration

```yaml
preview:
  enabled: true              # Enable preview environments for PRs
  kubernetes: true           # Deploy to Kubernetes cluster
  domain: example.com        # Base domain for preview URLs
  azure:
    resource_group: PREVIEW_RG      # Azure resource group for previews
  gcp:
    project_id: PREVIEW_PROJECT_ID  # GCP project for previews
```

**Notes**:
- Creates temporary environments for each Pull Request
- Automatically destroyed when PR is closed/merged
- Requires preview-specific secrets and variables

#### Observability Configuration

```yaml
observability:
  enabled: true              # Enable observability agents
  agent: xray                # Agent type: xray, newrelic, datadog, dynatrace (default: xray)
  config:
    # X-Ray Configuration
    configFilePath: /app/xray
    configFileName: xray-config.json
    contextMissingStrategy: LOG_ERROR
    tracingEnabled: "true"
    samplingStrategy: CENTRAL    # CENTRAL, LOCAL, NONE, ALL
    traceIdInjectionPrefix: ""
    samplingRulesManifest: "path-to-sampling-rules-manifest"
    awsServiceHandlerManifest: "path-to-aws-service-handler-manifest"
    awsSdkVersion: 1             # 1 or 2
    maxStackTraceLength: 50
    streamingThreshold: 100
    traceIdInjection: "true"
    contextPropagation: "true"
    pluginsEnabled: "true"
    collectSqlQueries: "false"
    
    # DataDog Configuration
    tags: tag1=value1,tag2=value2
    logs_enabled: "true"
    logs_config_container_collect_all: "true"
    container_exclude_logs: "name:datadog-agent"
    trace_debug: "false"
    logs_injection: "true"
    profiling_enabled: "true"
    trace_sample_rate: 1.0
    trace_sampling_rules: "path-to-sampling-rules"
    apm_non_local_traffic: "true"
    apm_enabled: "true"
    dogstatsd_non_local_traffic: "true"
    http_client_error_statuses: "400,401,403,404,405,409,410,429,500,501,502,503,504,505"
    http_server_error_statuses: "500,501,502,503,504,505"
```

**Supported Agents**:
- **X-Ray**: AWS native tracing (default)
- **New Relic**: Full-stack observability
- **DataDog**: APM, logs, metrics
- **Dynatrace**: Application performance monitoring

#### Cloud Provider & Deployment Type

```yaml
cloud: aws              # Target cloud: aws, azure, gcp
cloud_type: beanstalk   # Deployment type based on cloud:
                        # AWS: beanstalk, eks, lambda
                        # Azure: aks, webapp, function
                        # GCP: gke, appengine, cloudrun, kubernetes

runner_set: "arc-runner-set"  # GitHub runner set (optional, uses hosted runners by default)
```

**Important**: Only ONE `inputs-*.yaml` file can be used per environment. The file name indicates the deployment target.

---

### inputs-BEANSTALK-ENV.yaml

**Purpose**: Configuration for AWS Elastic Beanstalk deployments. Use this file when `cloud_type: beanstalk`.

#### Basic Configuration

```yaml
environment: "dev|uat|prod|demo"    # Target environment
runner_set: "RUNNER-ENV"            # Optional: Self-hosted runner set
disable_deploy: true                # Optional: Disable deployment
versions_bucket: "VERSIONS_BUCKET"  # S3 bucket for version storage
logs_bucket: "LOGS_BUCKET"          # Optional: S3 bucket for logs
blue_green: true                    # Enable for production (blue/green deployment)
container_registry: REGISTRY        # Container registry (required if preview enabled)
```

#### AWS Configuration

```yaml
aws:
  region: "us-east-1"                           # AWS region
  sts_role_arn: "arn:aws:iam::123456789012:role/..."  # Optional: STS role for build/deploy
  build_sts_role_arn: "arn:..."                 # Optional: Different role for build
  deploy_sts_role_arn: "arn:..."                # Optional: Different role for deploy
```

#### DNS Configuration

```yaml
dns:
  enabled: true                 # Enable DNS configuration
  private_zone: false           # Use Route53 private zone
  domain_name: example.com      # Domain name
  alias_prefix: app             # DNS prefix (e.g., app.example.com)
```

#### CloudWatch Alarms

```yaml
alarms:
  enabled: false                # Enable CloudWatch alarms
  threshold: 15                 # Alarm threshold
  period: 120                   # Evaluation period in seconds
  evaluation_periods: 2         # Number of periods to evaluate
  destination_topic: arn:aws:sns:...  # SNS topic for notifications
```

#### API Gateway Integration

```yaml
api_gateway:
  enabled: false                # Enable API Gateway integration
  vpc_link:
    link_name: VPC_LINK_NAME    # Optional: Only if NOT using existing link
    use_existing: false         # Use existing VPC link
    lb_name: LOAD_BALANCER_NAME # Load balancer name
    listener_port: 8443         # Listener port
    to_port: 443                # Target port
    health:
      enabled: true
      protocol: HTTPS
      http_status: "200-401"
      path: "/"
```

#### Elastic Beanstalk Configuration

**Solution Stack** (Choose one):
```yaml
beanstalk:
  solution_stack: java    # Platform selection
  
  # Available stacks:
  # java         = Amazon Linux 2023 + Corretto 21
  # java8        = Amazon Linux 2 + Corretto 8
  # java11       = Amazon Linux 2 + Corretto 11
  # java17       = Amazon Linux 2 + Corretto 17
  # java17_23    = Amazon Linux 2023 + Corretto 17
  # tomcat       = Amazon Linux 2023 + Tomcat + Corretto 21
  # tomcatj8     = Amazon Linux 2 + Tomcat + Corretto 8
  # tomcatj11    = Amazon Linux 2 + Tomcat + Corretto 11
  # tomcatj17    = Amazon Linux 2023 + Tomcat + Corretto 17
  # node         = Amazon Linux 2023 + Node.js 20
  # node22       = Amazon Linux 2023 + Node.js 22
  # node14-18    = Various Node.js versions
  # go           = Amazon Linux 2 + Go
  # docker       = Amazon Linux 2 + Docker
  # docker-m     = Amazon Linux 2 + Multi-container Docker
  # dotnet-core  = Amazon Linux 2 + .NET Core
  # dotnet-6/8/9 = Amazon Linux 2023 + .NET 6/8/9
  # python39-313 = Various Python versions
  # net-core-w*  = Windows Server Core + IIS
  # dotnet-w*    = Windows Server + IIS
  
  application: APPLICATION_NAME     # Elastic Beanstalk application name
  wait_for_ready_timeout: "20m"     # Optional: Timeout for health checks
  
  iam:
    instance_profile: INSTANCE_PROFILE  # EC2 instance profile
    service_role: SERVICE_ROLE          # Elastic Beanstalk service role
  
  load_balancer:
    # Shared Load Balancer (optional)
    #shared:
    #  dns:
    #    enabled: false
    #  enabled: false
    #  name: SHARED_LB_NAME
    #  weight: 100
    
    public: true                      # Public-facing load balancer
    ssl_certificate_id: arn:aws:acm:...  # ACM certificate ARN
    ssl_policy: ELBSecurityPolicy-2016-08
    alias: LOAD_BALANCER_ALIAS        # CNAME alias
  
  instance:
    instance_port: 8080               # Application port
    enable_spot: true                 # Enable spot instances
    default_retention: 90             # Spot instance retention days
    volume_size: 20                   # Root volume size (GB)
    volume_type: gp2                  # Volume type
    ec2_key: EC2_KEY_PAIR             # SSH key pair
    ami_id: AMI_ID                    # Custom AMI (optional)
    server_types:                     # EC2 instance types
      - t3.medium
      - t3.large
    #pool:                            # Instance scaling
    #  min: 1
    #  max: 1
  
  networking:
    private_subnets:                  # Private subnet IDs
      - subnet-xxx
      - subnet-yyy
    public_subnets:                   # Public subnet IDs
      - subnet-aaa
      - subnet-bbb
    vpc_id: vpc-xxxxx                 # VPC ID
```

#### Port Mappings (Optional)

```yaml
port_mappings:
  - name: default
    from_port: 80
    to_port: 8081
    protocol: HTTP
  - name: port443
    from_port: 443
    to_port: 8443
    protocol: HTTPS
    backend_protocol: HTTPS
    health_check:
      enabled: true
      protocol: HTTPS
      port: 8443
      matcher: "200-302"
      path: "/"
      unhealthy_threshold: 2
      healthy_threshold: 2
      timeout: 5
      interval: 30
    rules:
      - RULENAME
```

#### Extra Settings & Tags

```yaml
extra_tags:
  key: value
  key2: value2

extra_settings:
  - name: "PORT"
    namespace: "aws:elasticbeanstalk:application:environment"
    resource: ""
    value: "8080"
  - name: "SETTING_NAME"
    namespace: "aws:NAMESPACE"
    resource: ""
    value: "VALUE"

custom_shared_rules: true    # Enable custom shared load balancer rules

rule_mappings:
  - name: RULENAME
    process: port_mapping_process
    host: host1.com,host2.com
    path: /path
    priority: 100
    path_patterns:
      - /path
    query_strings:
      - query1=value1
    http_headers:
      - name: HEADERNAME
        values: ["value1", "valuepattern*"]
    source_ips:
      - 10.0.0.1
      - 10.0.0.2

tags:
  TAG1: value1
  TAG2: value2
```

---

### inputs-KUBERNETES-ENV.yaml

**Purpose**: Configuration for Kubernetes deployments (EKS, AKS, GKE). Use when `cloud_type: eks`, `aks`, `gke`, or `kubernetes`.

#### Basic Configuration

```yaml
environment: "dev|uat|prod|demo"    # Target environment
runner_set: "RUNNER-ENV"            # Optional: Self-hosted runner
disable_deploy: true                # Optional: Disable deployment
container_registry: REGISTRY        # Container registry URL
cluster_name: CLUSTER_NAME          # Kubernetes cluster name
namespace: NAMESPACE                # Kubernetes namespace

secret_files:
  enabled: false                    # Enable secret file mounting
  files_path: values/secrets        # Path to secret files
  mount_point: /app/secrets         # Mount path in container

config_map:
  enabled: false                    # Enable configmap mounting
  files_path: values/configmaps     # Path to config files
  mount_point: /app/configmap       # Mount path in container

helm_repo_url: oci://HELM_REPO_URL  # Helm repository URL (OCI or HTTPS)
helm_chart_name: CHART_NAME         # Helm chart name
helm_chart_path: CHART_PATH         # Local chart path (alternative to repo)

helm_values_overrides:
  'image.repository': REGISTRY/REPOSITORY  # Helm value overrides
```

#### Docker Build Arguments

```yaml
docker_args: |
  ARG1=value1
  ARG2=value2
  ARG3=value3
```

#### Cloud-Specific Configurations

**Azure AKS**:
```yaml
azure:
  resource_group: RESOURCE_GROUP              # Resource group (build & deploy)
  build_resource_group: RESOURCE_GROUP        # Optional: Build-specific RG
  deploy_resource_group: RESOURCE_GROUP       # Optional: Deploy-specific RG
  keyvault_name: KEYVAULT_NAME                # Azure Key Vault name
  keyvault_secret_filter: KEYVAULT_SECRET_FILTER  # Secret name filter
  external_secrets:
    enabled: true                     # Enable External Secrets Operator
    create_store: true                # Create ExternalSecretsStore
    store_name: "external-secrets-store"  # Store name if not creating
    refresh_interval: "1h"            # Secret refresh interval
    on_change: true                   # Trigger deployment on secret change
  pod_identity:
    enabled: true                     # Enable Azure AD Pod Identity
    identity_name: IDENTITY_NAME      # Managed identity name
```

**AWS EKS**:
```yaml
aws:
  region: us-east-1                           # AWS region
  sts_role_arn: "arn:aws:iam::..."            # STS role (build & deploy)
  build_sts_role_arn: "arn:..."               # Optional: Build-specific role
  deploy_sts_role_arn: "arn:..."              # Optional: Deploy-specific role
  secrets_path_filter: /secrets               # Secrets Manager path filter
  external_secrets:
    enabled: true                     # Enable External Secrets Operator
    create_store: true                # Create ExternalSecretsStore
    store_name: "external-secrets-store"
    refresh_interval: "1h"
    on_change: true                   # Trigger deployment on secret change
  pod_identity:
    enabled: true                     # Enable IRSA (IAM Roles for Service Accounts)
    iam_role_name: ROLE_NAME          # IAM role name
```

**GCP GKE**:
```yaml
gcp:
  region: us-central1                         # GCP region
  project_id: gcp-project-id                  # GCP project ID
  impersonate_sa: sa@project.iam.gserviceaccount.com  # Service account (build & deploy)
  build_impersonate_sa: sa@...                # Optional: Build-specific SA
  deploy_impersonate_sa: sa@...               # Optional: Deploy-specific SA
  secrets_path_filter: /secrets               # Secret Manager path filter
  external_secrets:
    enabled: true                     # Enable External Secrets Operator
    create_store: true                # Create ExternalSecretsStore
    store_name: "external-secrets-store"
    refresh_interval: "1h"
    on_change: true                   # Trigger deployment on secret change
  pod_identity:
    enabled: true                     # Enable Workload Identity
    service_account_name: SA_NAME     # Kubernetes service account
```

**Notes**:
- **External Secrets**: Automatically syncs secrets from cloud secret managers to Kubernetes Secrets
- **Pod Identity**: Enables pods to authenticate with cloud services without hardcoded credentials
- **Secret Filters**: Controls which secrets are synced from the secret manager

---

### inputs-LAMBDA-ENV.yaml

**Purpose**: Configuration for AWS Lambda function deployments. Use when `cloud_type: lambda` or `cloud_type: function`.

#### Basic Configuration

```yaml
environment: "dev|uat|prod|demo"    # Target environment
runner_set: "RUNNER-ENV"            # Optional: Self-hosted runner
disable_deploy: true                # Optional: Disable deployment
versions_bucket: "VERSIONS_BUCKET"  # S3 bucket for deployment packages
logs_bucket: "LOGS_BUCKET"          # Optional: S3 bucket for logs
container_registry: REGISTRY        # Container registry (for container-based Lambda)

aws:
  region: "us-east-1"                           # AWS region
  sts_role_arn: "arn:aws:iam::..."              # Optional: STS role
  build_sts_role_arn: "arn:..."                 # Optional: Build-specific role
  deploy_sts_role_arn: "arn:..."                # Optional: Deploy-specific role
```

#### Lambda Function Configuration

```yaml
lambda:
  arch: x86_64                      # Architecture: x86_64 or arm64
  
  iam:
    enabled: true                   # Enable IAM role creation
    execRole:
      enabled: true                 # Create execution role
      principals:
        - lambda.amazonaws.com
        - apigateway.amazonaws.com
    policy_attachments:
      - arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess
    statements:
      - effect: Allow
        action:
          - ec2:CreateNetworkInterface
          - ec2:DescribeNetworkInterfaces
          - ec2:DeleteNetworkInterface
          - ec2:AssignPrivateIpAddresses
          - ec2:UnassignPrivateIpAddresses
        resource: "*"
      - effect: Allow
        action:
          - ec2:DescribeSecurityGroups
          - ec2:DescribeSubnets
          - ec2:DescribeVpcs
        resource: "*"
      - effect: Allow
        action:
          - s3:PutObject
          - s3:GetObject
          - s3:DeleteObject
          - s3:ListBucket
        resource:
          - arn:aws:s3:::bucket-name
          - arn:aws:s3:::bucket-name/*
      - effect: Allow
        action:
          - dynamodb:PutItem
          - dynamodb:GetItem
          - dynamodb:DeleteItem
          - dynamodb:UpdateItem
          - dynamodb:Scan
          - dynamodb:Query
        resource:
          - arn:aws:dynamodb:region:account:table/table-name
          - arn:aws:dynamodb:region:account:table/table-name/*
      - effect: Allow
        action:
          - dynamodb:ListTables
        resource: "*"
  
  environment:
    variables:
      - name: ENV_VAR_NAME
        value: env_var_value
  
  handler: index.handler            # Lambda handler (package.method)
  runtime: java21                   # Runtime: java8, java11, java17, java21
  memory_size: 128                  # Memory in MB (default: 128)
  reserved_concurrency: -1          # Reserved concurrency (-1 = account limit)
  timeout: 3                        # Timeout in seconds (default: 3)
  
  # Provisioned Concurrency (enables if > 1)
  provisioned_concurrent_executions: 1
  
  # Alias Configuration (optional)
  alias:
    enabled: true
    name: "prod"                    # Alias name: prod, uat, dev, demo
    routing_config:
      - version: "1"                # Lambda version
        weight: 1.0                 # Traffic weight (0.0 to 1.0)
  
  # Function URLs (optional)
  functionUrls:
    - id: prod
      qualifier: "prod"
      authorizationType: "AWS_IAM"  # AWS_IAM or NONE
      cors:
        allowCredentials: true
        allowMethods:
          - "GET"
          - "POST"
        allowOrigins:
          - "*"
        allowHeaders:
          - "date"
          - "keep-alive"
        exposeHeaders:
          - "date"
          - "keep-alive"
        maxAge: 86400
    - id: "dev"
      authorizationType: "NONE"
```

#### EventBridge Scheduling

```yaml
schedule:
  enabled: false                    # Enable scheduled invocations
  schedule_group: "my-schedule-group"  # EventBridge schedule group
  flexible:
    enabled: true
    maxWindow: 20                   # Max window in minutes
  expression: "rate(1 hour)"        # Cron or rate expression
  timezone: "UTC-3"                 # Timezone for cron
  suspended: false                  # Suspend schedule
  payload: {}                       # Payload to send (YAML/JSON/string)
  
  # Multiple schedules (optional)
  multiple:
    - expression: "rate(1 hour)"
      flexible:
        enabled: true
        maxWindow: 20
      timezone: "UTC-3"
      suspended: false
      payload: {}
```

#### VPC Configuration

```yaml
vpc:
  enabled: false                    # Enable VPC attachment
  create_security_group: false      # Create new security group
  security_groups:
    - sg-1234567890abcdef0
    - sg-1234567890abcdef1
  subnets:
    - subnet-1234567890abcdef0
```

#### Logging Configuration

```yaml
logging:
  application_log_level: "INFO"     # Application log level
  log_format: JSON                  # JSON or Text
  system_log_level: INFO            # System log level: INFO, DEBUG, ERROR
```

#### X-Ray Tracing

```yaml
tracing:
  enabled: true                     # Enable X-Ray tracing
  mode: Active                      # Active or PassThrough
```

#### Ephemeral Storage

```yaml
ephemeral_storage:
  enabled: true                     # Increase ephemeral storage
  size: 1024                        # Size in MB (default: 512, max: 10240)
```

#### EFS Configuration

```yaml
efs:
  enabled: true                     # Enable EFS mount
  arn: arn:aws:elasticfilesystem:...  # EFS file system ARN
  local_mount_path: /mnt/efs        # Mount path in function
```

#### Event Source Triggers

```yaml
triggers:
  s3:
    bucketName: BUCKET_NAME
    events:
      - s3:ObjectCreated:*
    filterPrefix: "Logs/"
    filterSuffix: ".log"
  
  sqs:
    queueName: SQS_QUEUE_NAME
    batchSize: 10                   # Max items per batch (default: 10)
    maximumConcurrency: 2           # Max concurrent invocations
    metricsConfig: true             # Enable metrics
    filterCriteria:
      - pattern: '{ "body": { "Temperature": [ { "numeric": [ ">", 0, "<=", 100 ] } ] } }'
      - pattern_object:
          body:
            Temperature:
              - numeric:
                  - ">"
                  - 0
                  - "<="
                  - 100
  
  dynamodb:
    tableName: DYNAMODB_TABLE_NAME
    startingPosition: LATEST        # LATEST or TRIM_HORIZON
    batchSize: 100                  # Max records per batch (default: 100)
    maximumRetryAttempts: 3         # Max retry attempts (default: -1)
    metricsConfig: true             # Enable metrics
    filterCriteria:
      - pattern: '{ "body": { "Temperature": [ { "numeric": [ ">", 0 ] } ] } }'
```

#### Lambda Layers

```yaml
layers:
  - arn: arn:aws:lambda:us-east-1:123456789012:layer:my-layer:1
  - arn: arn:aws:lambda:us-east-1:123456789012:layer:my-layer:2
  - arn: arn:aws:lambda:us-east-1:901920570463:layer:aws-otel-java-agent-amd64-ver-1-32-0:4
```

#### Tags

```yaml
tags:
  key: value
  key2: value2
```

---

### inputs-CLOUDRUN.yaml

**Purpose**: Configuration for Google Cloud Run deployments. Use when `cloud_type: cloudrun`.

#### Basic Configuration

```yaml
environment: "dev|uat|prod|demo"    # Target environment
runner_set: "RUNNER-ENV"            # Optional: Self-hosted runner
disable_deploy: true                # Optional: Disable deployment
container_registry: REGISTRY        # Container registry (always required for Cloud Run)

gcp:
  region: "us-central1"             # GCP region
  project_id: "gcp-project-id"      # GCP project ID
  impersonate_sa: "sa@project.iam.gserviceaccount.com"  # Service account
  build_impersonate_sa: "sa@..."    # Optional: Build-specific SA
  deploy_impersonate_sa: "sa@..."   # Optional: Deploy-specific SA
```

#### Cloud Run Service Configuration

```yaml
cloudrun:
  type: service                     # Type: service, job, worker_pool
  ingress: all                      # Ingress: all, internal, internal_lb
  timeout: 10.123456789s            # Request timeout (default: 10s)
  concurrency: 80                   # Max concurrent requests (default: 80)
  working_dir: /workspace           # Container working directory
  default_url_disabled: false       # Disable default URL
  
  # Resource Limits
  limits:
    cpu: "1"                        # CPU: 0.25, 0.5, 1, 2, 4
    memory: "512Mi"                 # Memory: 128Mi to 16Gi
    nvidia.com/gpu: "1"             # GPU (requires GKE Autopilot)
  
  # Scaling Configuration
  scaling:
    min: 0                          # Minimum instances
    max: 2                          # Maximum instances
    count: 1                        # Required if mode is MANUAL
    mode: AUTOMATIC                 # AUTOMATIC or MANUAL (required)
  
  # Environment Variables & Secrets
  environment:
    variables:
      - name: ENV_VAR_NAME
        value: env_var_value
    secrets:
      - name: SECRET_ENV_VAR_NAME
        secret_name: my-secret
        version: latest
  
  # Port Configuration
  ports:
    - name: http1                   # http1 or h2c
      port: 8080
  
  # VPC Configuration
  vpc:
    connector:
      name: "projects/PROJECT/locations/REGION/connectors/CONNECTOR_NAME"
      egress: all                   # all or private-ranges-only
    network_interfaces:
      network: default
      subnetwork: default
  
  # Volume Configuration
  volumes:
    - name: secret-volume
      secret:
        secret_name: my-secret
        default_mode: "0444"
        items:
          - path: secret-file.txt
            version: latest
            mode: "0444"
    - name: cloudsql
      instances:
        - name: instance_name
          connection_name: project:region:instance
    - name: emptydir
      empty_dir:
        medium: "MEMORY"            # MEMORY (default) or ""
        size_limit: "100Mi"
    - name: gcs
      gcs:
        bucket_name: my-bucket      # Required
        read_only: false            # Default: false
        mount_options: []
    - name: nfs
      nfs:
        server: nfs-server.example.com  # Required
        path: /path/to/share        # Required
        read_only: false
  
  volume_mounts:
    - name: volume-name
      mount_path: /path/in/container
      sub_path: secret-file.txt
  
  # Health Probes
  liveness_probe:
    initial_delay: 0
    period: 1
    timeout: 1
    threshold: 3
    http_get:
      path: /health
      port: 8080
      http_headers:
        - name: Custom-Header
          value: Awesome
    grpc:
      port: 8080
      service: "grpc.service.Name"
    tcp_socket:
      port: 8080
  
  readiness_probe:
    initial_delay: 0
    period: 1
    timeout: 1
    threshold: 3
    http_get:
      path: /ready
      port: 8080
  
  startup_probe:
    initial_delay: 0
    period: 1
    timeout: 1
    threshold: 3
    http_get:
      path: /startup
      port: 8080
  
  # Event Triggers
  triggers:
    pubsub:
      topic: PUBSUB_TOPIC_NAME
    cloud_storage:
      bucket_name: BUCKET_NAME
      event_types:
        - finalized
        - deleted
      filter_prefix: "Logs/"
      filter_suffix: ".log"
```

---

### inputs-APPENGINE.yaml

**Purpose**: Configuration for Google Cloud App Engine deployments. Use when `cloud_type: appengine`.

#### Basic Configuration

```yaml
environment: "dev|uat|prod|demo"    # Target environment
runner_set: "RUNNER-ENV"            # Optional: Self-hosted runner
disable_deploy: true                # Optional: Disable deployment
versions_bucket: "VERSIONS_BUCKET"  # GCS bucket for versions
blue_green: true                    # Enable for production (blue/green)
container_registry: REGISTRY        # Container registry

gcp:
  region: "us-central1"             # GCP region
  project_id: "gcp-project-id"      # GCP project ID
  impersonate_sa: "sa@..."          # Service account
  build_impersonate_sa: "sa@..."    # Optional: Build-specific SA
  deploy_impersonate_sa: "sa@..."   # Optional: Deploy-specific SA
```

#### DNS & Monitoring

```yaml
dns:
  enabled: false                    # Enable DNS configuration
  private_zone: false               # Private DNS zone
  domain_name: example.com          # Domain name
  alias_prefix: app                 # DNS prefix

alarms:
  enabled: false                    # Enable Cloud Monitoring alarms
  threshold: 15                     # Alarm threshold
  period: 120                       # Evaluation period (seconds)
  evaluation_periods: 2             # Number of periods
  destination_topic: DESTINATION_SNS  # Notification topic
```

#### App Engine Configuration

```yaml
appengine:
  runtime: java21                   # Runtime: java21, java25, java17
  type: standard                    # standard or flexible
  entrypoint_shell: java -jar app.jar  # Startup command
  
  # IAM Configuration (optional)
  #iam:
  #  service_account: SA_NAME
  
  instance:
    class: B2                       # Instance class (standard)
    
    # Auto Scaling (standard)
    #auto_scaling:
    #  min: 0
    #  max: 1
    #  max_idle: 1
    #  min_idle: 1
    #  target_cpu: 0.6
    #  target_throughput: 0.6
    #  max_concurrent_requests: 10
    #  min_pending_latency: automatic
    #  max_pending_latency: automatic
    #  cool_down_period: 300
    
    # Basic Scaling (standard)
    basic_scaling:
      max: 1                        # Max instances
      idle_timeout: 300s            # Idle timeout
    
    # Manual Scaling (standard)
    #manual_scaling:
    #  count: 2
  
  # VPC Connector (optional)
  #networking:
  #  connector:
  #    create: true
  #    subnet_name: "serverless-subnet"
  #    name: "<connector name>"
  
  # HTTP Handlers (reference: https://cloud.google.com/appengine/docs/standard/reference/app-yaml)
  http_handlers: []
  
  # Environment Variables
  env_variables: {}
```

---

### inputs-LIB-ENV.yaml

**Purpose**: Configuration for library projects that deploy to Maven repositories instead of containers. Use when `is_library: true`.

#### Basic Configuration

```yaml
environment: "dev|uat|prod|demo"    # Target environment
runner_set: "RUNNER-ENV"            # Self-hosted runner (required for libraries)
```

#### Cloud-Specific Secret Management

**Azure**:
```yaml
azure:
  resource_group: RESOURCE_GROUP              # Resource group
  build_resource_group: RESOURCE_GROUP        # Optional: Build-specific RG
  deploy_resource_group: RESOURCE_GROUP       # Optional: Deploy-specific RG
  keyvault_name: KEYVAULT_NAME                # Key Vault name
```

**AWS**:
```yaml
aws:
  region: AWS_REGION                          # AWS region
  sts_role_arn: "arn:aws:iam::..."            # STS role
  build_sts_role_arn: "arn:..."               # Optional: Build-specific role
  deploy_sts_role_arn: "arn:..."              # Optional: Deploy-specific role
```

**GCP**:
```yaml
gcp:
  region: "us-central1"                       # GCP region
  project_id: "gcp-project-id"                # GCP project ID
  impersonate_sa: "sa@..."                    # Service account
  build_impresonate_sa: "sa@..."              # Optional: Build-specific SA
  secrets_path_filter: /secrets               # Secret Manager path filter
```

**Notes**:
- Library projects skip container builds
- Deploys JARs to Maven repository (GitHub Packages, Nexus, Artifactory)
- Configuration in `pom.xml` determines repository destination

---

## CloudOpsWorks CI Configuration

**File**: `.cloudopsworks/cloudopsworks-ci.yaml`

**Purpose**: Central configuration for repository settings, GitFlow workflow, branch protection, and CD pipeline behavior.

### Artifact Packaging

```yaml
zipGlobs:
  - target/libs/**          # Include dependency JARs
  - target/*.jar            # Include built JARs
  - conf/**                 # Include configuration files

excludeGlobs:
  - Dockerfile
  - .helmignore
  - .dockerignore
  - .git*
  - .git/
  - OWNER*
  - README.md
  - jenkins*
  - charts/*
  - cloudopsworks-ci*
  - skafold*
  - original-*.jar
  - tronador/*
  - .tronador
  - Makefile
  - apifiles/*
```

### Repository Configuration

```yaml
config:
  branchProtection: true            # Enable branch protection rules
  gitFlow:
    enabled: true                   # Enable GitFlow workflow
    supportBranches: false          # Enable support branches
  
  protectedSources:                 # Protected file patterns
    - "*.tf"
    - "*.tfvars"
    - OWNERS
    - Makefile
    - .github
  
  requiredReviewers: 1              # Required reviewers for PRs
  reviewers: []                     # Specific reviewers (optional)
  #  - user1
  #  - team-name
  
  owners: []                        # Branch owners (can commit to protected)
  #  - user1
  #  - org/team-name
  
  contributors:                     # Repository member permissions
    admin:
      - cloudopsworks/admin
    triage: []
    pull: []
    push:
      - cloudopsworks/engineering
    maintain: []
```

### CD Pipeline Configuration

```yaml
cd:
  automatic: false                  # Auto-merge/deploy to lower envs
  
  deployments:
    develop:
      env: dev                      # Deploy develop -> dev environment
      #variables:
      #  var1: value1
      #  DEPLOYMENT_AWS_REGION: us-east-1
      #  DEPLOYMENT_AWS_STS_ROLE_ARN: arn:aws:iam::...
      #enabled: false
      #targetName: dev-target
    
    release:
      env: prod                     # Deploy release -> prod environment
      #reviewers: false             # Override required reviewers
      #targetName: prod-target
      #targets:                     # Multiple production targets
      #  my-target:
      #    env: prod-my-target
      #    targetName: prod-my-target
    
    test:
      env: uat                      # Deploy release branches -> uat
      #enabled: false
      #targetName: uat-target
    
    prerelease:
      env: demo                     # Deploy pre-release tags -> demo
      #enabled: false
      #targetName: demo-target
      #targets:
      #  my-target:
      #    env: demo-my-target
      #    targetName: demo-my-target
    
    hotfix:
      env: hotfix                   # Deploy hotfix branches
      #targetName: hotfix-target
    
    support:                        # Support branch deployments
      - match: 1.5.*
        env: demo
        targetName: demo
      - match: 1.3.*
        env: demo2
        targetName: demo2
```

**GitFlow Deployment Criteria**:
| Branch/Tag Pattern | Deployment | Notes |
|-------------------|------------|-------|
| `develop` | develop | Development branch |
| `release/**` | test | Release candidate |
| TAG on `release/**` (v*.*.*-alpha/beta.*) | prerelease | Pre-release with qualifiers |
| TAG on `main/master` (v*.*.*) | release | Production release |
| TAG on `main/master` (v*.*.*+deploy-*) | release/targets | Production with specific targets |
| `support/**` | support x.y.* | Maintenance branches |

---

## API Gateway Configuration

**Directory**: `.cloudopsworks/vars/apigw/`

**Purpose**: Define API Gateway configurations for different environments. Each environment has its own file (`apis-dev.yaml`, `apis-uat.yaml`, `apis-prod.yaml`), with a global configuration file (`apis-global.yaml`).

### Global Configuration (apis-global.yaml)

```yaml
provider: aws               # API Gateway provider: aws, azure, gcp
apis:
  - name: test              # API name
    version: v2             # API version
```

### Environment-Specific Configuration

**File Pattern**: `apis-{environment}.yaml`

#### Example: apis-dev.yaml

```yaml
environment: dev            # Environment name

apigw_definitions:
  - name: test              # API name (must match global)
    version: v2             # API version
    mapping: test-apis/api/2.0  # API mapping path
    domain_name: apigw-dev.sample.com  # Custom domain
    file_name: test         # API definition file (without extension)
    stage_variables:
      - name: api_variable
        value: api_value

aws:
  stage: dev                # API Gateway stage name
  stage_only: false         # Deploy stage only (no API)
  
  # API Type (uncomment for HTTP API)
  #http_api: true
  
  # Endpoint Configuration
  #endpoint_type: REGIONAL
  #vpc_endpoint_ids:
  #  - vpce-1234567890abcdef0
  
  # API Settings
  #disable_execute_api_endpoint: false
  #minimum_compression_size: null
  #xray_enabled: true
  #cache_cluster_enabled: true
  #cache_cluster_size: 0.5
  
  # VPC Link (REST APIs)
  rest_vpc_link_name: test-link-dev
  #http_vpc_link:           # HTTP API VPC link
  #  id: VPC_LINK_ID
  #  server_name: test.dev.cloudopsworks.co
  #  type: lb | cloudmap
  #  lb:
  #    name: test-elb-dev
  #    listener_port: 80
  
  # Warnings & Logging
  #fail_on_warnings: false
  #log_location: /aws/apigateway
  #log_retention_days: 30
  
  # WAF Configuration (REST APIs only)
  #waf:
  #  enabled: true
  #  name: waf-name
  #  arn: waf-arn
  #  scope: REGIONAL  # REGIONAL or CLOUDFRONT
  
  # Stage Settings
  #settings:
  #  metrics_enabled: true
  #  logging_level: OFF | ERROR | INFO
  #  data_trace_enabled: true
  #  throttling_burst_limit: 10000
  #  throttling_rate_limit: 5000
  #  caching_enabled: true
  #  cache_ttl_in_seconds: 300
  #  cache_data_encrypted: true
  #  require_authorization_for_cache_control: true
  #  unauthorized_cache_control_header_strategy: FAIL_WITH_403
  
  # Backup Configuration
  publish_bucket:
    enabled: false
    name: test-apigw-backup
    prefix_path: test
  
  # Custom Parameters for API definitions
  #custom_parameters:
  #  - name: url
  #    value: test-api.dev.sample.com
  
  # Stage Variables
  stage_variables:
    - name: url
      value: test-api.dev.sample.com
  
  # Lambda Options (HTTP APIs only)
  #lambda_options:
  #  format_version: "1.0"  # "1.0" or "2.0"
  #  responses:
  #    default:
  #      statusCode: "200"
  #  pass_through_behavior: when_no_match
  #  timeout_millis: 30000
  #  content_handling: CONVERT_TO_TEXT
  
  # Authorizers
  authorizers:
    - name: Lambda-Auth
      authtype: lambda      # lambda, jwt, aws_iam
      #scheme:
      #  name: Authorization
      #  in: header
      #  type: apiKey
      #  authtype: custom
      #result_ttl_seconds: 10
      #identity_source: method.request.header.Authorization
      #type: request
      lambda:
        function: lambda-auth-dev  # Lambda function name
        exec_role: lambda-auth-dev-lambda-exec-role

tags: {}                    # Resource tags
```

**Available Files**:
- `apis-global.yaml`: Global API definitions
- `apis-dev.yaml`: Development environment
- `apis-uat.yaml`: UAT environment
- `apis-prod.yaml`: Production environment

**Notes**:
- API definition files (`.yaml` or `.json`) must exist in `apifiles/` directory
- Each environment can have different stages, domains, and configurations
- Authorizers can be Lambda-based, JWT, or IAM

---

## Helm Chart Configuration

**Directory**: `.cloudopsworks/vars/helm/`

**Purpose**: Helm values overrides for Kubernetes deployments. Based on Cloud Ops Works Helm Chart templates from [blueprints repository](https://github.com/cloudopsworks/blueprints/tree/master/kubernetes/helm/charts).

**Available Files**:
- `values-dev.yaml`: Development environment overrides
- `values-uat.yaml`: UAT environment overrides
- `values-prod.yaml`: Production environment overrides

### Complete Helm Chart Options

The following options are available based on the Cloud Ops Works Helm Chart templates:

#### Deployment Type Configuration

**StatefulSet** (for stateful applications):
```yaml
statefulset:
  enabled: true
```

**DaemonSet** (run on every node):
```yaml
daemonset:
  enabled: true
```

**Job** (one-time execution):
```yaml
job:
  enabled: true
```

**CronJob** (scheduled execution):
```yaml
cronjob:
  enabled: true
  restartPolicy: OnFailure
```

#### Deployment Metadata

```yaml
# Deployment Annotations
annotations: {}
  # reloader.stakater.com/auto: "true"  # Auto-reload on secret change

# Pod Annotations
podAnnotations: {}
  # instrumentation.opentelemetry.io/inject-java: "true"
```

#### Scheduling & Placement

```yaml
# Affinity & Anti-Affinity
affinity: {}
  # nodeAffinity:
  #   requiredDuringSchedulingIgnoredDuringExecution:
  #     nodeSelectorTerms:
  #       - matchExpressions:
  #           - key: kubernetes.io/e2e-az-name
  #             operator: In
  #             values:
  #               - e2e-az1

# Tolerations
tolerations: {}
  # - key: "key1"
  #   operator: "Equal"
  #   value: "value1"
  #   effect: "NoSchedule"

# Node Selector
nodeSelector: {}
  # disktype: ssd
```

#### Storage Configuration

```yaml
# Additional Volume Mounts
additionalVolumeMounts: {}
  # - name: config-volume
  #   mountPath: /etc/config
  #   readOnly: true

# Additional Volumes
additionalVolumes: {}
  # - name: config-volume
  #   configMap:
  #     name: my-config
```

#### Scaling & Replicas

```yaml
# Replica Count (Deployment/StatefulSet)
replicaCount: 1

# Deployment Strategy
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
```

#### Environment Variables

```yaml
# Direct Environment Variables
env:
  - name: ENV_VAR_NAME
    value: "ENV VAR VALUE"

# Environment from ConfigMap/Secret
envFrom: {}
  # configMapRef:
  #   name: my-configmap
  # secretRef:
  #   name: my-secret
```

#### Health Probes

```yaml
# Base probe path
probe:
  path: /healthz
  # port: 8082

# Startup Probe
startupProbe:
  enabled: true
  # initialDelaySeconds: 0
  # periodSeconds: 10
  # failureThreshold: 30
  # timeoutSeconds: 1

# Liveness Probe
livenessProbe: {}
  # httpGet:
  #   path: /healthz
  #   port: 8080
  # initialDelaySeconds: 30
  # periodSeconds: 10
  # failureThreshold: 3

# Readiness Probe
readinessProbe: {}
  # httpGet:
  #   path: /ready
  #   port: 8080
  # initialDelaySeconds: 5
  # periodSeconds: 5
  # failureThreshold: 3
```

#### Resource Limits

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 400m
    memory: 512Mi
```

#### Ingress Configuration

```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  rules:
    - host: APP-URL
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: PROJECT_NAME-helm
                port:
                  number: 80
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local
```

#### Horizontal Pod Autoscaler (HPA)

```yaml
hpa:
  enabled: false
  minReplicas: 2
  maxReplicas: 6
  cpuTargetAverageUtilization: 80
  memoryTargetAverageUtilization: 80
  
  # Enable Metrics
  cpuPercentage: true
  memoryPercentage: true
  
  # Advanced Options
  stabilizationWindowSeconds: 300
  percentValueDown: 40
  percentPeriodDown: 60
  percentValueUp: 80
  percentPeriodUp: 60
  
  # External Metrics
  external:
    enabled: true
    name: external-metric
    labelSelector:
      labelKey: labelValue
    averageValue: 50
```

#### Service Account

```yaml
serviceAccount:
  enabled: false            # Use default service account
  create: false             # Create new service account
  annotations: {}
    # eks.amazonaws.com/role-arn: arn:aws:iam::...
  name: ""                  # Custom name (if not creating)
```

#### KEDA ScaledObject (Advanced Autoscaling)

```yaml
keda:
  enabled: true
  annotations:
    scaledobject.keda.sh/transfer-hpa-ownership: "true"
    validations.keda.sh/hpa-ownership: "true"
    autoscaling.keda.sh/paused: "true"
  
  envSourceContainerName: container-name
  pollingInterval: 30           # Seconds
  cooldownPeriod: 300           # Seconds
  initialCooldownPeriod: 0      # Seconds
  idleReplicaCount: 0
  minReplicaCount: 1
  maxReplicaCount: 100
  
  # Fallback Configuration
  fallback:
    failureThreshold: 3
    replicas: 6
    behavior: "static"
  
  # Advanced Configuration
  advanced:
    restoreToOriginalReplicaCount: false
    horizontalPodAutoscalerConfig:
      name: custom-hpa-name
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
            - type: Percent
              value: 100
              periodSeconds: 15
  
  # Triggers (define scaling triggers)
  triggers: {}
    # - type: prometheus
    #   metadata:
    #     serverAddress: http://prometheus:9090
    #     metricName: http_requests_total
    #     query: sum(rate(http_requests_total[2m]))
    #     threshold: '100'
```

**Notes**:
- Each environment file overrides base chart values
- Use `helm_values_overrides` in `inputs-*.yaml` for dynamic overrides
- KEDA provides event-driven autoscaling beyond standard HPA

---

## Preview Environment Configuration

**Directory**: `.cloudopsworks/vars/preview/`

**Purpose**: Configuration for temporary preview environments created for Pull Requests.

### inputs.yaml

```yaml
environment: "preview"        # Fixed environment name

config_map:
  enabled: false
  files_path: values/configmaps
  mount_point: /var/configmaps

helm_values_overrides: {}     # Helm value overrides for preview

# Cloud-Specific Secret Management
azure:
  keyvault_name: KEYVAULT_NAME
  keyvault_secret_filter: KEYVAULT_SECRET_FILTER
  pod_identity:
    enabled: true
    identity_name: IDENTITY_NAME

aws:
  secrets_path_filter: /secrets
  pod_identity:
    enabled: true
    iam_role_name: ROLE_NAME

gcp:
  secrets_path_filter: /secrets
  pod_identity:
    enabled: true
    service_account_name: SERVICE_ACCOUNT_NAME
```

### values.yaml

```yaml
image:
  pullPolicy: Always        # Always pull for previews

ingress:
  enabled: true
  ingressClassName: nginx
  rules:
    - host: preview.example.com  # Preview domain
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: preview-helm
                port:
                  number: 80

service:
  externalPort: 80
  internalPort: 8080
```

**Preview Environment Lifecycle**:
1. Created when PR is opened from `feature/**` or `hotfix/**`
2. Deployed to Kubernetes cluster
3. Unique URL generated (e.g., pr123.preview.example.com)
4. Automatically destroyed when PR is closed/merged

**Required Organization Variables**:
- `PREVIEW_AWS_REGION` / `PREVIEW_AZURE_RESOURCE_GROUP` / `PREVIEW_GCP_PROJECT`
- `PREVIEW_DOCKER_REGISTRY_ADDRESS`
- `PREVIEW_RUNNER_SET`
- `PREVIEW_AWS_EKS_CLUSTER_NAME` / `PREVIEW_AZURE_AKS_CLUSTER_NAME` / `PREVIEW_GCP_GKE_CLUSTER_NAME`
- `PREVIEW_RANCHER_PROJECT_ID` (if using Rancher)

---

## Deployment Targets

### Target Selection Matrix

| File | Cloud | Deployment Type | Use Case |
|------|-------|----------------|----------|
| `inputs-BEANSTALK-ENV.yaml` | AWS | Elastic Beanstalk | Traditional Java apps, Tomcat |
| `inputs-KUBERNETES-ENV.yaml` | AWS/Azure/GCP | EKS/AKS/GKE | Containerized apps, microservices |
| `inputs-LAMBDA-ENV.yaml` | AWS | Lambda | Serverless functions, event-driven |
| `inputs-CLOUDRUN.yaml` | GCP | Cloud Run | Serverless containers |
| `inputs-APPENGINE.yaml` | GCP | App Engine | Managed platform, standard/flexible |
| `inputs-LIB-ENV.yaml` | Any | Maven Repo | Java libraries, SDKs |

### Important Notes

1. **One File Per Environment**: Only ONE `inputs-*.yaml` file can be active per environment. The file name indicates the deployment target.

2. **Environment Naming**: Environment names must match between:
   - `inputs-*.yaml` `environment` field
   - `cloudopsworks-ci.yaml` deployment configuration
   - GitHub environment name

3. **Runner Sets**:
   - `DEPLOYMENT_RUNNER_SET`: Production deployments
   - `PREVIEW_RUNNER_SET`: Preview environments
   - Can be overridden per configuration file

4. **Secrets & Variables**: Must be configured at GitHub Organization level:
   - Build secrets: `BUILD_*`
   - Deployment secrets: `DEPLOYMENT_*`
   - Preview secrets: `PREVIEW_*`

5. **API Gateway**: Only supported for AWS currently. Configure in `.cloudopsworks/vars/apigw/`

6. **Helm Values**: Environment-specific overrides in `.cloudopsworks/vars/helm/`

---

## Quick Start Guide

### 1. Initial Setup

1. Copy template to new repository
2. Configure organization-level secrets and variables
3. Update `.cloudopsworks/cloudopsworks-ci.yaml` with repository settings
4. Select deployment target and update corresponding `inputs-*.yaml`

### 2. Configure Build

1. Update `pom.xml` with project details
2. Configure `inputs-global.yaml`:
   - Set organization details
   - Enable/disable security scanning
   - Configure observability
3. Set Java version and Docker options

### 3. Configure Deployment

1. Choose deployment target file:
   - `inputs-BEANSTALK-ENV.yaml` for Elastic Beanstalk
   - `inputs-KUBERNETES-ENV.yaml` for Kubernetes
   - etc.
2. Update cloud-specific settings:
   - Region, VPC, subnets
   - IAM roles and permissions
   - Resource specifications
3. Configure environment-specific values in `helm/values-*.yaml`

### 4. Configure APIs (Optional)

1. Add API definitions to `apifiles/`
2. Configure `apigw/apis-global.yaml`
3. Configure environment-specific `apis-*.yaml`

### 5. Enable Preview Environments (Optional)

1. Update `.cloudopsworks/vars/preview/inputs.yaml`
2. Configure preview domain
3. Set up preview-specific secrets

### 6. First Deployment

1. Commit and push to `develop` branch
2. Monitor GitHub Actions
3. Verify deployment in target environment

---

## Troubleshooting

### Common Issues

1. **Deployment Fails with Permission Errors**
   - Verify IAM roles and STS role ARNs
   - Check GitHub secrets are correctly configured
   - Ensure runner has necessary permissions

2. **Preview Environment Not Created**
   - Verify `preview.enabled: true` in `inputs-global.yaml`
   - Check `PREVIEW_*` organization variables
   - Ensure PR is from `feature/**` or `hotfix/**` branch

3. **Security Scanning Fails**
   - Verify tool tokens (Snyk, SonarQube, etc.)
   - Check network connectivity to scanning services
   - Review quality gate thresholds

4. **Helm Deployment Fails**
   - Validate `helm_values_overrides` syntax
   - Check cluster connectivity
   - Verify Helm repository access

### Support

- **Documentation**: https://cloudops.works
- **GitHub Issues**: https://github.com/cloudopsworks/blueprints/issues
- **Email**: https://cowk.io/email
- **Slack**: https://cowk.io/slack

---

## License

Copyright © 2021-2025 Cloud Ops Works LLC. Distributed under Apache License 2.0.
