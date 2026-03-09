---
name: cloud-infrastructure
description: "Cloud architecture, Infrastructure as Code (Terraform/CDK), Kubernetes, CI/CD pipelines, deployment strategies, and container orchestration patterns for AWS, Azure, and GCP."
argument-hint: "[topic: terraform | kubernetes | cicd | deployment | architecture]"
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# Cloud Infrastructure Patterns

## Infrastructure as Code

### Terraform Best Practices

```hcl
# Module structure
modules/
  vpc/
    main.tf          # Resources
    variables.tf     # Input variables
    outputs.tf       # Output values
    versions.tf      # Provider constraints
  rds/
  ecs/
environments/
  dev/
    main.tf          # Module calls with dev values
    backend.tf       # Remote state config
  staging/
  production/
```

#### State Management
- **Remote backend**: S3 + DynamoDB (AWS), GCS (GCP), Azure Blob — never local state in production
- **State locking**: Prevent concurrent modifications
- **State isolation**: Separate state per environment
- **Import existing resources**: `terraform import` before managing manually-created resources

#### Safety Patterns
- Always run `terraform plan` before `apply`
- Use `-target` for risky changes to limit blast radius
- Tag all resources for cost tracking and ownership
- Use `prevent_destroy` lifecycle rule on databases and storage
- Pin provider versions: `required_providers { aws = { version = "~> 5.0" } }`

### CDK / Pulumi Patterns
- Use constructs/components for reusable infrastructure
- Test infrastructure with unit tests (CDK assertions, Pulumi testing)
- Synthesize and diff before deploying

## Kubernetes

### Pod Design
```yaml
# Production-ready pod spec
spec:
  containers:
    - name: app
      image: app:v1.2.3          # Always pin versions, never :latest
      resources:
        requests:                 # Scheduling guarantee
          cpu: 100m
          memory: 128Mi
        limits:                   # Hard ceiling
          cpu: 500m
          memory: 512Mi
      livenessProbe:              # Restart if unhealthy
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 15
      readinessProbe:             # Remove from LB if not ready
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 5
      securityContext:
        runAsNonRoot: true
        readOnlyRootFilesystem: true
        allowPrivilegeEscalation: false
```

### Deployment Strategies
- **Rolling update**: Default, zero-downtime, gradual replacement
- **Blue-Green**: Two full environments, instant switch via service/ingress
- **Canary**: Route percentage of traffic to new version, monitor, then promote
- **Feature flags**: Deploy code dark, enable per-user/percentage

### Scaling
- **HPA**: Scale on CPU, memory, or custom metrics (queue depth, request latency)
- **VPA**: Right-size resource requests based on actual usage
- **Cluster autoscaler**: Add/remove nodes based on pending pods
- **KEDA**: Event-driven scaling (queue length, cron schedules)

## CI/CD Pipeline Design

### GitHub Actions Structure
```yaml
name: CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - run: npm run lint

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=high
      - uses: github/codeql-action/analyze@v3

  deploy-staging:
    needs: [test, security]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to staging
        run: ./deploy.sh staging

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production  # Requires approval
    steps:
      - name: Deploy to production
        run: ./deploy.sh production
```

### Pipeline Principles
- **Fast feedback**: Lint and unit tests first (< 2 min), integration tests after
- **Fail fast**: Stop pipeline on first failure
- **Cache aggressively**: Dependencies, build artifacts, Docker layers
- **Environment gates**: staging → manual approval → production
- **Rollback plan**: Every deployment must have a one-command rollback

## Deployment Strategies

### Blue-Green
1. Deploy new version to idle environment (green)
2. Run health checks and smoke tests on green
3. Switch load balancer/DNS to green
4. Keep old environment (blue) running for instant rollback
5. After verification period, decommission blue

### Canary
1. Deploy new version alongside old (1 new pod, 9 old)
2. Route 10% of traffic to canary
3. Monitor error rates, latency, business metrics for 15-30 min
4. If healthy: promote to 50% → 100%
5. If unhealthy: roll back canary immediately

### Zero-Downtime Database Migrations
1. Deploy code that handles both old and new schema
2. Run forward migration (additive only — new columns, new tables)
3. Backfill data in batches
4. Deploy code that uses new schema only
5. Drop old columns/tables in a later release

## Observability

### The Three Pillars

| Pillar | Tool | Purpose |
|--------|------|---------|
| **Logs** | ELK, CloudWatch, Loki | Debug specific requests, audit trail |
| **Metrics** | Prometheus, CloudWatch, DataDog | Trends, alerts, dashboards |
| **Traces** | Jaeger, X-Ray, OpenTelemetry | Request flow across services |

### SLI/SLO Framework
- **SLI** (Service Level Indicator): Measurable metric (e.g., "99.5% of requests complete in < 200ms")
- **SLO** (Service Level Objective): Target for the SLI (e.g., "99.9% availability per month")
- **Error budget**: SLO gap that allows for planned risk (deployments, experiments)

## Cost Optimization

- **Right-size instances**: Use metrics to find over-provisioned resources
- **Spot/preemptible instances**: For stateless, fault-tolerant workloads (CI runners, batch jobs)
- **Reserved capacity**: For steady-state workloads (databases, core services)
- **Auto-scaling**: Scale down during off-peak hours
- **Tag everything**: Track costs by team, project, environment
