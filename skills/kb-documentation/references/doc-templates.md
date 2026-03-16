# Documentation Templates

## README Template

```markdown
# Project Name

One-line description of what this project does.

## Prerequisites

- [Requirement 1] (version X.Y+)
- [Requirement 2]

## Quick Start

\`\`\`bash
# Clone and install
git clone <repo-url>
cd project-name
[install command]

# Run
[run command]
\`\`\`

## Usage

### [Feature 1]
[Description and examples]

### [Feature 2]
[Description and examples]

## Development

### Setup
\`\`\`bash
[dev setup commands]
\`\`\`

### Testing
\`\`\`bash
[test commands]
\`\`\`

### Building
\`\`\`bash
[build commands]
\`\`\`

## Project Structure

\`\`\`
src/
├── [dir]/    # [Purpose]
├── [dir]/    # [Purpose]
└── [file]    # [Purpose]
\`\`\`

## Contributing

[Guidelines or link to CONTRIBUTING.md]

## License

[License type] — see [LICENSE](LICENSE)
```

## API Documentation Template

```markdown
# API Reference

## Authentication

[How to authenticate]

## Endpoints

### [Resource Name]

#### Create [Resource]
\`\`\`
POST /api/resource
\`\`\`

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Resource name |

**Response:** `201 Created`
\`\`\`json
{
  "id": "abc123",
  "name": "Example"
}
\`\`\`

**Errors:**
| Code | Description |
|------|-------------|
| 400 | Invalid input |
| 401 | Unauthorized |

#### List [Resources]
\`\`\`
GET /api/resources?page=1&limit=20
\`\`\`

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| page | integer | 1 | Page number |
| limit | integer | 20 | Items per page |
```

## Architecture Documentation Template

```markdown
# Architecture Overview

## System Diagram

[Description or ASCII diagram of system components]

## Components

### [Component 1]
- **Purpose:** [What it does]
- **Technology:** [Stack used]
- **Key files:** [Entry points]

### [Component 2]
...

## Data Flow

1. [Step 1: User action]
2. [Step 2: Processing]
3. [Step 3: Response]

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Database | PostgreSQL | ACID compliance needed for financial data |
| Cache | Redis | Sub-ms latency for session storage |

## Deployment

[How the system is deployed and where]
```

## Changelog Template

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- [New feature description]

### Changed
- [Modified behavior description]

### Fixed
- [Bug fix description]

### Removed
- [Removed feature description]

## [1.0.0] - 2024-01-15

### Added
- Initial release
```
