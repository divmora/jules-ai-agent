# Jules AI Agent

[![Latest Release](https://img.shields.io/github/v/release/divmora/jules-ai-agent?logo=github)](https://github.com/divmora/jules-ai-agent/releases)
[![Go Version](https://img.shields.io/github/go-mod/go-version/divmora/jules-ai-agent)](go.mod)
[![Documentation: DeepWiki](https://img.shields.io/badge/docs-DeepWiki-blue.svg)](https://deepwiki.com/divmora/jules-ai-agent)
[![CI/CD](https://github.com/divmora/jules-ai-agent/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/divmora/jules-ai-agent/actions)
[![License: BSL 1.1](https://img.shields.io/badge/License-BSL_1.1-blue.svg)](https://github.com/divmora/.github/blob/main/LICENSING.md)
[![Security Policy](https://img.shields.io/badge/Security-Policy-green.svg)](SECURITY.md)

**Jules** is a suite of autonomous AI code review and engineering agents powered by [LocalHarness](https://github.com/divmora/localharness). Jules agents autonomously inspect your target codebase, identify targeted domain-specific improvements, implement surgical code modifications on dedicated Git branches, run test and lint verification suites, and submit clean Pull Requests.

---

## Specialized Agents

Jules includes four domain-specialized agents:

| Agent | Domain | Mission & Focus Areas |
| :--- | :--- | :--- |
| **Sentinel 🛡️** | **Security** | Audits code for vulnerabilities: hardcoded secrets, SQL injection, XSS, CSRF, insecure endpoints, and data leaks. |
| **Palette 🎨** | **Design & UX** | Identifies micro-UX and accessibility improvements: ARIA labels, focus states, keyboard navigation, missing loading/disabled states, empty states, and contrast. |
| **Bolt ⚡** | **Performance** | Pinpoints bottlenecks and inefficiencies: N+1 queries, unoptimized loops, missing caches, unnecessary React re-renders, payload compression, and memory leaks. |
| **Sweeper 🧹** | **Maintainability** | Cleans up technical debt and code smells: vague naming, magic numbers, complex boolean logic, bloated functions, duplicate code, and outdated syntax. |

---

## How It Works

All Jules agents operate via a deterministic **Plan-and-Solve** agentic lifecycle:

1. **Memory & Reflection**: Prior to starting, the agent reads its long-term journal in `.jules/<agent>.md` (if present) to recall past architectural decisions and avoid repeating pitfalls.
2. **Analysis & Selection**: Scans the workspace and isolates the single highest-priority issue that can be cleanly resolved in less than 50 lines.
3. **Branch Creation**: Checks out a dedicated descriptive Git branch (e.g., `perf/bolt-optimize-loops` or `sec/sentinel-fix-csrf`).
4. **Implementation**: Implements surgical, well-commented fixes.
5. **Verification**: Executes workspace linters and test suites (`make lint`, `make test`, `pnpm test`, etc.) to guarantee zero regressions.
6. **Journal Reflection (Conditional)**: Appends non-obvious codebase learnings to `.jules/<agent>.md` only if novel insights were discovered.
7. **Atomic Commit & PR**: Stages all changes in a single commit and creates a structured Pull Request.

---

## Usage & Execution

Jules can be executed natively as a standalone binary or inside an isolated containerized workspace.

### 1. Running Locally (Native)

Ensure **Go 1.25+** is installed:

```bash
# Build the binary to bin/
make build

# Run Sentinel to audit security
./bin/jules-ai-agent --agent sentinel --workspace /path/to/project --prompt "Audit codebase for security vulnerabilities"

# Run Bolt to optimize performance
./bin/jules-ai-agent --agent bolt --workspace /path/to/project --prompt "Identify and fix the most critical performance bottleneck"

# Run Palette for accessibility and UX
./bin/jules-ai-agent --agent palette --workspace /path/to/project --prompt "Improve keyboard navigation and ARIA accessibility"

# Run Sweeper for maintainability cleanup
./bin/jules-ai-agent --agent sweeper --workspace /path/to/project --prompt "Clean up technical debt and refactor bloated routines"
```

### 2. Running via Docker (Isolated Workspace)

Jules provides a pre-configured Ubuntu Noble development container packed with developer toolchains (Node.js 22, Python 3.12, Go, PHP 8.4, Docker-in-Docker, and systemd):

```bash
# Start the Jules workspace container
docker compose up -d --build

# Run an agent inside the isolated workspace
docker compose exec jules bash -c "jules --agent sentinel --workspace /workspace/project --prompt 'Audit for security vulnerabilities'"
```

---

## Configuration & CLI Flags

| Flag | Type | Description | Default |
| :--- | :--- | :--- | :--- |
| `--agent` | string | **(Required)** Agent to run: `bolt`, `palette`, `sentinel`, or `sweeper` | `""` |
| `--workspace` | string | Target workspace directory path to analyze | `"."` |
| `--prompt` | string | **(Required)** Task instructions and context prompt for the agent | `""` |
| `--verbose` | bool | Enable verbose/debug logging output from the agent runtime | `false` |

---

## Development & Building

### Prerequisites

- **Go 1.25+**: [golang.org](https://golang.org/dl/)
- **Make**: Standard build automation tool
- **Docker**: For containerized workspace builds and verification

### Available Make Targets

```bash
# Build binary to bin/
make build

# Run unit tests
make test

# Run unit tests with race detection and coverage
make test-coverage

# Format Go source code
make fmt

# Run linter
make lint

# Cross-compile for all supported operating systems and architectures
make build-all

# Build local Docker image
make docker-build

# Build multi-architecture Docker image with buildx
make docker-build-multiarch

# Clean build artifacts
make clean
```

---

## Community & Contributing

- **[Contributing Guide](CONTRIBUTING.md)**: Guidelines for local setup, pull requests, and Conventional Commits.
- **[Agent Guidelines](AGENTS.md)**: Agentic architecture, subagents, and memory journal conventions.
- **[Living Product Roadmap](ROADMAP.md)**: Upcoming architectural items and feature plans.
- **[Code of Conduct](https://github.com/divmora/.github/blob/main/CODE_OF_CONDUCT.md)**: Contributor Covenant Code of Conduct.
- **[Security Policy](SECURITY.md)**: Vulnerability disclosure channels and SLAs.

---

## License & Commercial Use

This project is licensed under the **Business Source License 1.1 (BSL 1.1)**.

- **Non-Production & Evaluation:** Free to use, modify, and test in non-production environments (local development, staging, QA, CI/CD automated validation, and proof-of-concept evaluation).
- **Production & Commercial Use:** Deploying or executing in production environments, embedding into commercial products, or offering as a managed service requires a commercial license (EULA) from **DIVMORA Technologies**.
- **Open Source Transition:** Each release automatically converts to the **Apache License, Version 2.0** three (3) years after its initial release date.

For commercial licensing inquiries or enterprise support, please contact **licensing@divmora.com** or visit [divmora.com](https://divmora.com).
