# Curly Spork

A Docker-based project that builds customizable color variants of OpenShift rollout demonstration images.

## Overview

This project is based on `quay.io/openshiftdemos/rollouts-demo`, which provides a simple web application for demonstrating rollout strategies.

## Available Colors

The base image supports various colors. Common options include:
- green (default)
- blue
- red
- yellow
- orange
- purple


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

## CI/CD Pipeline

The project also includes a comprehensive GitHub Actions workflow (`.github/workflows/ci.yaml`) that implements a  GitOps deployment pipeline with commit tracking capabilities.

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

The workflow implements  commit tracking through multiple mechanisms:

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
   - Supports environment progression (dev � staging � production)
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

## GitOps Repository

For the complete GitOps deployment configuration and rendered Kubernetes manifests, see the deployment repository: [refactored-robot](https://github.com/ihonwub/refactored-robot)

This repository contains:
- Helm values for different environments (`values/envs/`)
- Rendered Kubernetes manifests
- GitOps deployment patterns and best practices