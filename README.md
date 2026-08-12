# Jules AI Agents

Jules is a suite of specialized AI code review agents powered by `github.com/divmora/localharness`. The agents autonomously analyze your workspace to find performance, design, or security issues, implement the changes on a new branch, and prepare the final updates.

## Setup

1. Build and run the Jules workspace using Docker Compose:
   ```bash
   docker compose up -d --build
   ```

## Running an Agent

You can execute agents inside the running container. For example, to run Bolt against an `fms` workspace:

```bash
docker compose exec jules bash -c "jules --agent bolt --workspace /workspace/fms --prompt 'Analyze the codebase for performance issues'"
```

### Available Agents:
- **Bolt** (Performance optimization)
- **Palette** (Design and UX improvements)
- **Sentinel** (Security vulnerability fixes)

See `.agents/AGENTS.md` for more details on each agent's capabilities and workflows.
