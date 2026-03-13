# CI/CD Patterns

## GitHub Actions

### Basic CI Pipeline
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

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build
      - uses: actions/upload-artifact@v4
        with: { name: build, path: dist/ }
```

### Docker Build and Push
```yaml
  docker:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
```

### Deploy to Cloud
```yaml
  deploy:
    needs: [test, build]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - run: |
          # Deploy command here
```

## GitLab CI

```yaml
stages: [test, build, deploy]

test:
  stage: test
  image: node:20
  script:
    - npm ci
    - npm test
    - npm run lint

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
  script:
    - # Deploy command
```

## Best Practices

### Pipeline Design
- Fail fast: run quick checks (lint, type check) before slow tests
- Cache dependencies between runs (`actions/cache`, `npm ci`)
- Use matrix builds for multiple versions/platforms
- Separate build and deploy stages
- Use environment protections for production deploys

### Security
- Never echo secrets in logs
- Use short-lived tokens and OIDC where possible
- Pin action versions to specific SHAs
- Scan dependencies for vulnerabilities in CI
- Use `--frozen-lockfile` / `npm ci` to ensure reproducible builds

### Artifacts
- Upload build artifacts between jobs
- Tag Docker images with commit SHA (not `latest` in production)
- Store test reports and coverage as artifacts
- Clean up old artifacts with retention policies
