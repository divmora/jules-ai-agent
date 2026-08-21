# Jules AI Agents

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/divmora/jules-ai-agent)

Jules is a suite of specialized AI code review agents powered by `github.com/divmora/localharness`. The agents autonomously analyze your workspace to find performance, design, or security issues, implement the changes on a new descriptive branch, and prepare the final pull requests.

## How to Use

Jules can be run natively on your machine or inside an isolated Docker environment. API keys and context should be provided directly via user prompts or through MCP tool configurations.

### 1. Running Locally (Native)

If you have Go 1.25+ installed, you can build and run Jules directly on your local codebase:

```bash
# Build the agent for current platform
make build

# Or cross-compile for all supported platforms (linux/amd64, linux/arm64, darwin/amd64, darwin/arm64, windows/amd64)
make build-all

# Run the agent against a local workspace
./jules-ai-agent --agent bolt --workspace /path/to/your/project --prompt "Analyze the codebase for performance issues and fix them."
```

### 2. Running via Docker (Isolated)

For an isolated environment with pre-installed toolchains (Node.js, Python, Go, PHP, etc.), use the provided Docker setup:

```bash
# Build and run the Jules workspace
docker compose up -d --build

# Or build multi-arch Docker image with Buildx (linux/amd64, linux/arm64)
make docker-build-multi

# Execute an agent inside the running container
docker compose exec jules bash -c "jules --agent sentinel --workspace /workspace/fms --prompt 'Audit for security vulnerabilities'"
```

## Available Agents

- **Bolt ⚡** (Performance optimization)
- **Palette 🎨** (Design and UX improvements)
- **Sentinel 🛡️** (Security vulnerability fixes)

For detailed capabilities, agent philosophies, and their specific Git workflows, see [`.agents/AGENTS.md`](.agents/AGENTS.md).
