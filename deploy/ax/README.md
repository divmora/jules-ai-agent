# Jules AI Agent on Google AX (Agent Executor)

This directory contains declarative specifications and guides for orchestrating [Jules AI Agent](https://github.com/divmora/jules-ai-agent) on [Google AX](https://github.com/google/ax).

---

## 🌟 Overview

**Google AX** is an open-source declarative orchestrator designed for managing autonomous AI agent workloads on Kubernetes and Agent Substrate. It treats agents as stateful actors with native sandboxing, zero-trust network boundaries, and sub-second suspension/resumption.

### How Jules Runs in Google AX

```
   ┌───────────────────────────────────────────────┐
   │            Google AX Control Plane            │
   │      (ax apply -f deploy/ax/task-*.yaml)      │
   └──────────────────────┬────────────────────────┘
                          │ Schedules Task
                          ▼
   ┌───────────────────────────────────────────────┐
   │         AX Sandbox (gVisor / Substrate)       │
   │                                               │
   │  ┌─────────────────────────────────────────┐  │
   │  │   ax-task-runner (PID 1)                │  │
   │  │   • Metadata server (:80)               │  │
   │  │   • Clones/prepares /workspace          │  │
   │  │   • Supervises task command child       │  │
   │  │   • Keeps sandbox alive for inspection  │  │
   │  └───────────────────┬─────────────────────┘  │
   │                      │ executes spec.command  │
   │                      ▼                        │
   │  ┌─────────────────────────────────────────┐  │
   │  │   jules --agent sentinel ...            │  │
   │  │   • Security audit & CVE fixes          │  │
   │  │   • Runs tests & linter in sandbox      │  │
   │  │   • Creates Git branch and patches      │  │
   │  └─────────────────────────────────────────┘  │
   └───────────────────────────────────────────────┘
```

1. **`ax-task-runner` as PID 1:** Every AX task container runs `/usr/local/bin/ax-task-runner` as PID 1.
2. **Workspace Preparation:** It binds declared `Workspace` resources (cloning git repositories, configuring environment variables).
3. **Agent Supervision:** It executes `jules` as defined in `spec.command` with full terminal streaming.
4. **Post-Execution Inspection:** When `jules` finishes, `ax-task-runner` keeps the container open for inspection via `ax ssh`.

---

## 📦 Building the AX Image

Build the dedicated AX task image locally using the Makefile:

```bash
make docker-build-ax
```

Or build for multi-architecture (`linux/amd64,linux/arm64`):

```bash
make docker-build-ax-multiarch
```

---

## 🚀 Running Jules via Google AX

### 1. Configure the Target Workspace

Edit [workspace.yaml](workspace.yaml) to point to your target Git repository:

```yaml
apiVersion: ax.io/v1alpha1
kind: Workspace
metadata:
  name: target-workspace
spec:
  git:
    - repo: https://github.com/my-org/my-repository.git
      branch: main
  path: /workspace
```

Apply the workspace:

```bash
ax apply -f deploy/ax/workspace.yaml
```

### 2. Launch a Jules Agent Task

Choose the persona you wish to run:

| Persona | Purpose | Manifest |
| :--- | :--- | :--- |
| **Sentinel** 🛡️ | Security vulnerability detection and patching | [task-sentinel.yaml](task-sentinel.yaml) |
| **Bolt** ⚡ | Performance bottleneck and query optimization | [task-bolt.yaml](task-bolt.yaml) |
| **Sweeper** 🧹 | Technical debt cleanup and maintainability | [task-sweeper.yaml](task-sweeper.yaml) |
| **Palette** 🎨 | Accessibility (WCAG 2.1 AA) and micro-UX | [task-palette.yaml](task-palette.yaml) |

Apply the task manifest:

```bash
ax apply -f deploy/ax/task-sentinel.yaml
```

### 3. Monitor and Inspect

Stream the task execution log:

```bash
ax watch task jules-sentinel-audit
```

SSH directly into the running sandbox:

```bash
ax ssh task jules-sentinel-audit
```

Check task details and metadata:

```bash
ax describe task jules-sentinel-audit
```

---

## 🐳 Direct Docker Execution (Without AX)

The image can also be run directly with Docker by overriding the entrypoint:

```bash
docker run --rm -it \
  -e GEMINI_API_KEY="your-gemini-key" \
  -v $(pwd):/workspace \
  --entrypoint jules \
  ghcr.io/divmora/jules-ai-agent-ax:latest \
  --agent sentinel \
  --workspace /workspace \
  --prompt "Audit for security vulnerabilities"
```
