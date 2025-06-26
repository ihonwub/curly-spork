# Curly Spork

A Docker-based project that builds customizable color variants of OpenShift rollout demonstration images.

## Overview

This project uses the OpenShift rollouts demo base image and allows you to build different color variants for testing and demonstration purposes.

## Usage

### Build the Docker image

Build with default color (green):
```bash
docker build -t curly-spork .
```

Build with custom color:
```bash
docker build --build-arg COLOR=blue -t curly-spork:blue .
```

### Run the container

```bash
docker run -p 8080:8080 curly-spork
```

## Available Colors

The base image supports various colors. Common options include:
- green (default)
- blue
- red
- yellow

## Base Image

This project is based on `quay.io/openshiftdemos/rollouts-demo`, which provides a simple web application for demonstrating OpenShift rollout strategies.

## CI/CD Pipeline

The project includes a comprehensive GitHub Actions workflow (`.github/workflows/ci.yaml`) that implements a complete GitOps deployment pipeline with advanced commit tracking capabilities.

### Workflow Overview

The CI/CD pipeline consists of two main jobs:

#### 1. Build and Push Docker Images (`build-and-push-image`)

**Triggers**: Automatically runs on pushes to the `main` branch

**Multi-Platform Build Process**:
- Sets up QEMU for cross-platform emulation
- Configures Docker Buildx for multi-architecture builds
- Builds images for both `linux/amd64` and `linux/arm64` platforms
- Authenticates with GitHub Container Registry (GHCR) using repository secrets

**Image Tagging Strategy**:
- `latest` - always points to the most recent successful build
- `<commit-sha>` - specific commit-based tag for precise versioning and rollback capabilities
- Images are pushed to `ghcr.io/<repository-name>` with lowercase naming compliance

**Output Generation**: The job outputs the full image name with commit SHA tag for use in the deployment job.

#### 2. GitOps Deployment (`deploy-dev`)

**Deployment Automation**:
- Installs `yq` (YAML processor) for programmatic YAML manipulation
- Clones the deployment repository (`refactored-robot`) using a Personal Access Token
- Updates the development environment configuration (`values/envs/dev.yaml`) with the new image tag
- Follows GitOps principles by modifying infrastructure-as-code configurations

**Commit Tracking & Metadata**:

The workflow implements sophisticated commit tracking through multiple mechanisms:

1. **Structured Commit Messages**: 
   - Format: `chore(dev): deploy <full-image-name-with-tag>`
   - Example: `chore(dev): deploy ghcr.io/user/curly-spork:abc123def`
   - Provides clear deployment history and image traceability

2. **Git Notes Integration**:
   - **Purpose**: Enables advanced deployment tracking without cluttering commit history
   - **Metadata Stored**:
     - `image: <full-image-name-with-tag>` - Records exactly what was deployed
     - `env: dev` - Tracks target environment for multi-environment workflows
   - **Implementation**: Uses `git notes add` with force flag to ensure notes are always updated
   - **Persistence**: Notes are pushed to `refs/notes/*` for permanent storage

3. **Promotion Workflow Support**:
   - Git Notes enable automated promotion pipelines to query deployment state
   - Supports environment progression (dev ’ staging ’ production)
   - Provides deployment audit trail for compliance and rollback scenarios

**Git Configuration**:
- Uses dedicated "Deploy Bot" identity for deployment commits
- Separates deployment commits from development commits for clear attribution

### Viewing Deployment History

**Standard Git Log**:
```bash
git log --oneline --grep="chore(dev): deploy"
```

**Git Notes (Deployment Metadata)**:
```bash
git log --show-notes
# or
git notes show <commit-hash>
```

**Query Specific Deployments**:
```bash
# Find what's deployed in dev environment
git log --notes --grep="env: dev" -1
```

### Security Considerations

- Uses GitHub's built-in `GITHUB_TOKEN` for container registry authentication
- Requires `DEPLOY_PAT` secret for cross-repository deployment updates
- Follows principle of least privilege with specific permission scopes
- Repository secrets are managed through GitHub's encrypted secrets system

### GitOps Benefits

This implementation provides:
- **Declarative Configuration**: All deployment state is stored in version control
- **Audit Trail**: Complete history of what was deployed when and by whom
- **Rollback Capability**: Easy reversion using git history and commit SHAs
- **Environment Isolation**: Separate configuration files for different environments
- **Automated Consistency**: Reduces manual deployment errors and configuration drift

The combination of structured commits and Git Notes creates a robust deployment tracking system that supports both human operators and automated tooling for managing application lifecycles across multiple environments.