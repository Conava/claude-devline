---
name: kb-cloud-infra
description: Domain logic for cloud infrastructure and DevOps — injected into the devops agent. Provides guidance on cloud-native development, IaC, containerization, CI/CD, and deployment. Not invoked directly.
user-invocable: false
disable-model-invocation: true
---

# Cloud & Infrastructure

Guidance for cloud-native development, infrastructure as code, containerization, and deployment across all major cloud providers and platforms.

## Pipeline Context

When running inside the devline pipeline via the devops agent, this skill guides infrastructure tasks. The devops agent follows TDD (via the kb-tdd-workflow skill) for infra changes too — write validation scripts or smoke tests before making changes. For example: write a test that checks a Docker image builds and starts correctly before writing the Dockerfile.

## Provider Detection

Before writing cloud or infrastructure code, detect the project's cloud ecosystem:

1. Check for `terraform/`, `.tf` files → Terraform/OpenTofu
2. Check for `Dockerfile`, `docker-compose.yml` → Docker
3. Check for `k8s/`, `kubernetes/`, Helm charts → Kubernetes
4. Check for `serverless.yml` → Serverless Framework
5. Check for `cdk.json` or `Pulumi.yaml` → CDK/Pulumi
6. Check for `.github/workflows/` → GitHub Actions CI/CD
7. Check for `Jenkinsfile`, `.gitlab-ci.yml`, `azure-pipelines.yml` → CI/CD
8. Check `.claude/devline.local.md` for `cloud_provider` override

Use the find-docs skill (`npx ctx7@latest`) for current cloud SDK and service documentation.

## Containerization

### Dockerfile Best Practices

- Use multi-stage builds to minimize image size
- Pin base image versions (not `latest`)
- Order layers from least to most frequently changing
- Use `.dockerignore` to exclude unnecessary files
- Run as non-root user
- Health checks for production containers
- One process per container

### Docker Compose

- Use named volumes for persistent data
- Define networks for service isolation
- Use environment files (`.env`) for configuration
- Pin image versions in production

## Infrastructure as Code

### General Principles

- All infrastructure defined in code, version controlled
- Use modules/components for reusability
- Separate environments (dev, staging, prod) with variables
- State management (remote state for Terraform)
- Plan before apply — review changes

### Security

- Never hardcode credentials in IaC files
- Use IAM roles and service accounts over access keys
- Encrypt data at rest and in transit
- Principle of least privilege for all permissions
- Enable audit logging

## CI/CD Pipelines

### Pipeline Stages

1. **Build** — Compile, install dependencies
2. **Test** — Unit tests, integration tests, linting
3. **Security** — Dependency scanning, SAST, secrets detection
4. **Package** — Build artifacts, container images
5. **Deploy** — Deploy to target environment
6. **Verify** — Smoke tests, health checks

### Best Practices

- Fail fast — run quick checks first
- Cache dependencies between builds
- Use environment-specific configurations
- Implement rollback strategies
- Never deploy without tests passing

## Additional Resources

### Reference Files

For provider-specific patterns:

- **`references/aws-patterns.md`** — AWS services, CDK, Lambda, ECS patterns
- **`references/container-patterns.md`** — Docker, Kubernetes, Helm best practices
- **`references/cicd-patterns.md`** — GitHub Actions, GitLab CI, Jenkins patterns
