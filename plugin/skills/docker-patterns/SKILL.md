---
name: docker-patterns
description: "Docker and Docker Compose conventions, multi-stage builds, security, and layer optimization. Auto-loaded when working with Dockerfiles or docker-compose files."
disable-model-invocation: false
user-invocable: false
---

# Docker Patterns

Domain knowledge for Docker and Docker Compose. Follow these conventions when writing Dockerfiles and compose configurations.

## Multi-Stage Builds

- Always use multi-stage builds: deps, build, production
- Copy dependency manifests first, install, then copy source (layer caching)
- Prune dev dependencies before copying to production stage
- Use `--chown` on COPY to avoid separate `chown` layer

### Language Templates

**Node.js:** `node:22-alpine` -- `npm ci` in deps stage, `npm run build && npm prune --production` in build, copy `dist/` + `node_modules/` to production

**Go:** `golang:1.22-alpine` -- `go mod download` then `CGO_ENABLED=0 go build -ldflags="-s -w"`, copy single binary to `alpine` or `scratch`

**Python:** `python:3.12-slim` -- install `uv`, `uv pip install --system -r requirements.txt`, copy site-packages + bins to production stage

**Rust:** `rust:1.77-slim` -- `cargo build --release` in builder, copy binary to `debian:bookworm-slim` or `scratch` (for musl builds)

**Java:** `eclipse-temurin:21-jdk-alpine` -- `./gradlew bootJar` or `mvn package`, copy JAR to `eclipse-temurin:21-jre-alpine`

## Docker Compose for Local Dev

- Use `target: dev` to select the dev stage of a multi-stage Dockerfile
- Bind mount source for hot reload: `- .:/app`
- Anonymous volume to preserve container deps: `- /app/node_modules`
- Use `depends_on` with `condition: service_healthy` for database readiness
- Use `docker-compose.override.yml` for dev-only settings (auto-loaded)
- Use separate `docker-compose.prod.yml` for production overrides
- Named volumes for persistent data (postgres, redis)
- One process per container -- never bundle multiple services

## .dockerignore

Always include: `node_modules`, `.git`, `.env`, `.env.*`, `dist`, `coverage`, `*.log`, build caches (`.next`, `.cache`), `Dockerfile*`, `docker-compose*.yml`

## Security

- Pin base image tags to specific versions -- never use `:latest`
- Create and switch to non-root user: `addgroup`/`adduser` then `USER appuser`
- Set `no-new-privileges:true` in compose `security_opt`
- Use `read_only: true` with `tmpfs` mounts for writable paths
- Drop all capabilities (`cap_drop: ALL`), add back only what's needed
- Never put secrets in image layers -- use env vars, `.env` files (gitignored), or Docker secrets
- Use `env_file` for local dev, secrets manager for production

## Layer Optimization

- Order instructions from least to most frequently changing
- Combine `RUN` commands with `&&` to reduce layers
- Use `--no-cache` flags for package managers (`pip --no-cache-dir`, `npm ci`)
- Clean up package manager caches in the same `RUN` layer
- Use `COPY --from=` to cherry-pick only needed artifacts from build stages

## Health Checks

- Add `HEALTHCHECK` instruction in production Dockerfiles
- Use `wget -qO-` or `curl -f` against `/health` endpoint
- Set `--interval=30s --timeout=3s --start-period=5s --retries=3`
- In compose, use `healthcheck` on database services (`pg_isready`, `redis-cli ping`)

## Networking

- Services in same compose network resolve by service name
- Use custom networks to isolate tiers: frontend can reach API, only API can reach DB
- Bind dev ports to `127.0.0.1` to avoid exposing to network: `"127.0.0.1:5432:5432"`
- Omit `ports` entirely for services that only need internal access

## Anti-Patterns to Avoid

- Running containers as root
- Using `:latest` or unversioned tags
- Storing data without volumes (containers are ephemeral)
- Putting secrets in `docker-compose.yml` or Dockerfile
- One giant container with all services
- Using `docker compose` in production without orchestration (use K8s, ECS, etc.)
- Copying entire repo in one `COPY .` layer before installing dependencies
- Installing dev dependencies in production images
