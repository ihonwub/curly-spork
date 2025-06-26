# Curly Spork

Builds customizable color variants of rollout demo images.

## Quick Start

Build with default color:
```bash
docker build -t curly-spork .
docker run -p 8080:8080 curly-spork
```

Build with custom color:
```bash
docker build --build-arg COLOR=blue -t curly-spork:blue .
```

**Available colors**: green (default), blue, red, yellow, orange, purple

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci.yaml`) implements GitOps deployment with commit tracking:

### Build Job
- Triggers on `main` branch pushes
- Builds multi-arch images (`linux/amd64`, `linux/arm64`)
- Pushes to GHCR with tags: `latest` and `<commit-sha>`

### Deploy Job
- Updates `values/envs/dev.yaml` in [refactored-robot](https://github.com/ihonwub/refactored-robot) repo
- Creates structured commits: `chore(dev): deploy <image-name>`
- Adds Git Notes with deployment metadata:
  - `image: <full-image-name>`
  - `env: dev`

### Viewing Deployments

```bash
# View deployment commits
git log --oneline --grep="chore(dev): deploy"

# View deployment metadata
git log --show-notes
```

## GitOps Repository

See [refactored-robot](https://github.com/ihonwub/refactored-robot) for:
- Helm values and Kubernetes manifests
- GitOps deployment patterns