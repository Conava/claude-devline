# Cloud & Infrastructure Reference

On-demand knowledge for infra tasks (build, CI/CD, Docker/containers, IaC, deployment). The implementer reads this when a task is infrastructure-flavored. Use the find-docs skill (`npx ctx7@latest`) for current cloud SDK and service docs.

## Provider / Ecosystem Detection

Before writing infra code, detect what the project uses:

1. `terraform/`, `.tf` → Terraform/OpenTofu
2. `Dockerfile`, `docker-compose.yml` → Docker
3. `k8s/`, `kubernetes/`, Helm charts → Kubernetes
4. `serverless.yml` → Serverless Framework
5. `cdk.json` / `Pulumi.yaml` → CDK/Pulumi
6. `.github/workflows/` → GitHub Actions
7. `Jenkinsfile`, `.gitlab-ci.yml`, `azure-pipelines.yml` → other CI/CD
8. `.claude/devline.local.md` `cloud_provider` override

Apply TDD to infra too: write a validation script or smoke test before the change (e.g., a test that the Docker image builds and starts before writing the Dockerfile).

## Containerization

**Dockerfile:** multi-stage builds; pin base image versions (not `latest`); order layers least→most frequently changing; `.dockerignore`; run as non-root; health checks in prod; one process per container.

**Compose:** named volumes for persistence; networks for isolation; `.env` for config; pin image versions in prod.

### Multi-stage Dockerfile (Node.js)
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
RUN addgroup -g 1001 app && adduser -u 1001 -G app -s /bin/sh -D app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER app
EXPOSE 3000
HEALTHCHECK CMD wget -q --spider http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### Multi-stage Dockerfile (Go)
```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o server .

FROM scratch
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Docker Compose
```yaml
services:
  api:
    build: .
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/app
    depends_on:
      db: { condition: service_healthy }
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: pg_isready -U user -d app
      interval: 5s
      retries: 5
volumes:
  pgdata:
```

### Kubernetes (Deployment / Service / HPA)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata: { name: api }
spec:
  replicas: 3
  selector: { matchLabels: { app: api } }
  template:
    metadata: { labels: { app: api } }
    spec:
      containers:
        - name: api
          image: api:latest
          ports: [{ containerPort: 3000 }]
          resources:
            requests: { cpu: 100m, memory: 128Mi }
            limits: { cpu: 500m, memory: 512Mi }
          livenessProbe: { httpGet: { path: /health, port: 3000 } }
          readinessProbe: { httpGet: { path: /ready, port: 3000 } }
---
apiVersion: v1
kind: Service
metadata: { name: api }
spec:
  selector: { app: api }
  ports: [{ port: 80, targetPort: 3000 }]
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: api }
spec:
  scaleTargetRef: { apiVersion: apps/v1, kind: Deployment, name: api }
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource: { name: cpu, target: { type: Utilization, averageUtilization: 70 } }
```

**Helm:** `values.yaml` for env-specific config; template deployment/service/ingress; `helm lint` before deploy; pin chart versions in prod.

## Infrastructure as Code

All infra in version-controlled code; modules/components for reuse; separate dev/staging/prod via variables; remote state (Terraform); plan before apply.

**Security:** never hardcode credentials; IAM roles/service accounts over access keys; encrypt at rest and in transit; least privilege; enable audit logging.

## CI/CD Pipelines

Stages: Build → Test → Security (dep scan, SAST, secrets) → Package → Deploy → Verify (smoke/health).

**Best practices:** fail fast (quick checks first); cache dependencies; env-specific config; rollback strategies; never deploy without tests passing; pin action versions to SHAs; short-lived tokens/OIDC; tag Docker images with commit SHA (not `latest`) in prod; store test reports/coverage as artifacts.

### GitHub Actions (CI + Docker build/push)
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - run: npm test
      - run: npm run lint
  docker:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with: { registry: ghcr.io, username: ${{ github.actor }}, password: ${{ secrets.GITHUB_TOKEN }} }
      - uses: docker/build-push-action@v5
        with: { push: true, tags: "ghcr.io/${{ github.repository }}:${{ github.sha }}" }
```

### GitLab CI
```yaml
stages: [test, build, deploy]
test:
  stage: test
  image: node:20
  script: [npm ci, npm test, npm run lint]
build:
  stage: build
  image: docker:latest
  services: [docker:dind]
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
deploy:
  stage: deploy
  only: [main]
  script: [echo "deploy command"]
```

## AWS Patterns

**Common architectures:** Serverless (API Gateway → Lambda → DynamoDB/S3/SQS); Container (ALB → ECS Fargate → RDS/ElastiCache/S3); Full-stack (CloudFront → S3 static + ALB → ECS/EKS → RDS/ElastiCache).

**CDK snippets:**
```typescript
const fn = new lambda.Function(this, 'Handler', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('lambda'),
  environment: { TABLE_NAME: table.tableName },
});
table.grantReadWriteData(fn);

const api = new apigateway.RestApi(this, 'Api');
api.root.addResource('items').addMethod('GET', new apigateway.LambdaIntegration(fn));

new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'Service', {
  taskImageOptions: { image: ecs.ContainerImage.fromAsset('./app'), environment: { DB_HOST: db.instanceEndpoint.hostname } },
  desiredCount: 2,
});
```

**Security:** IAM roles not access keys; CloudTrail audit logging; Secrets Manager for credentials; KMS encryption at rest; VPC isolation; GuardDuty; least-privilege security groups.

**Cost:** Savings Plans/Reserved for predictable load; Spot for fault-tolerant batch; right-size from CloudWatch; S3 lifecycle policies; billing alerts.
