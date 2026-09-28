# AGENTS.md — Jules AI Coding Agents

Guidelines, architecture context, and workflows for autonomous coding agents operating within and on `jules-ai-agent`.

---

## 1. Project Architecture Layout

```
jules-ai-agent/
├── main.go                       # CLI entrypoint; parses flags, initialises ADK agent, streams events
├── agents/                       # Agent prompt, subagent definitions, and configuration logic
│   ├── agents.go                 # Shared base configuration, binary resolver, and policies
│   ├── bolt.go                   # Bolt (Performance) agent config & prompt
│   ├── palette.go                # Palette (Design & UX) agent config & prompt
│   ├── sentinel.go               # Sentinel (Security) agent config & prompt
│   └── sweeper.go                # Sweeper (Maintainability) agent config & prompt
├── scripts/                      # Runtime scripts for container environments
│   ├── clone-repo.sh             # Workspace Git clone utility
│   ├── environment-summary.sh    # Container toolchain sanity and version reporter
│   └── git-askpass.sh            # Git authentication helper
├── deploy/                       # Orchestrator deployments and declarative manifests
│   └── ax/                       # Google AX (Agent Executor) Task & Workspace manifests
├── Dockerfile                    # Multi-stage Ubuntu Noble container with complete developer toolchains
├── Dockerfile.ax                 # Google AX task runner container with ax-task-runner as PID 1
├── docker-compose.yml            # Local container runner
├── Makefile                      # Standardized build and test targets
├── .release-please-config.json   # Release Please configuration
├── .release-please-manifest.json # Release Please version tracker
└── .goreleaser.yaml              # Multi-architecture compilation and archive packaging
```

---

## 2. Jules Agent Roles & Specializations

Jules includes four autonomous AI agents built on top of the **LocalHarness ADK** (`github.com/divmora/localharness`):

### Sentinel 🛡️ (Security)
- **Mission**: Identify and fix security vulnerabilities or add security enhancements.
- **Philosophy**: Security is everyone's responsibility. Defense in depth. Trust nothing, verify everything.
- **Focus Areas**: Hardcoded credentials, SQL injection, XSS, CSRF, insecure endpoints, SSRF, broken access control, and data leakage.
- **Subagent**: Spawns `vuln-researcher` for read-only data-flow and taint analysis across deep call chains.

### Palette 🎨 (Design & UX)
- **Mission**: Find and implement micro-UX improvements that make interfaces more intuitive and accessible.
- **Philosophy**: Users notice the little things. Accessibility is not optional. Good UX is invisible.
- **Focus Areas**: WCAG compliance, ARIA attributes, semantic HTML, focus states, keyboard trap prevention, missing loading/disabled states, empty states, and contrast ratios.
- **Subagent**: Spawns `a11y-auditor` for read-only component auditing against WCAG 2.1 AA standards.

### Bolt ⚡ (Performance)
- **Mission**: Identify and implement performance improvements to make the application faster and more efficient.
- **Philosophy**: Speed is a feature. Measure first, optimize second. Every millisecond counts.
- **Focus Areas**: N+1 queries, unoptimized loops, missing database indices, missing caches, unnecessary React re-renders, uncompressed payloads, and memory leaks.
- **Subagent**: Spawns `perf-researcher` for read-only performance bottleneck tracing.

### Sweeper 🧹 (Maintainability)
- **Mission**: Clean up technical debt and improve code readability without altering external behavior.
- **Philosophy**: Code is read much more often than it is written. Clarity is better than cleverness. Leave the codebase cleaner than you found it.
- **Focus Areas**: Ambiguous identifiers, magic numbers, bloated functions, dead code, complex boolean logic, duplicate code, and modern language syntax adoption.

---

## 3. Agentic Architecture & Operational Workflow

All Jules agents follow a strict, deterministic **Plan-and-Solve** workflow:

### Step 1: Read Memory Journal First
Before initiating analysis, the agent checks for an existing memory journal in `.jules/<agent>.md` (e.g. `.jules/bolt.md`) in the target workspace. If found, the agent reviews historical findings and pitfalls to avoid redundant investigations.

### Step 2: Workspace Analysis & Problem Selection
The agent audits the target workspace and selects the single highest-impact issue that can be cleanly resolved in **less than 50 lines of code**.

### Step 3: Branch Checkout
Prior to modifying code, the agent creates a dedicated descriptive Git branch:
```bash
git checkout -b <domain>/<agent>-<concise-description>
# Examples:
#   perf/bolt-memoize-selector
#   sec/sentinel-sanitize-input
#   a11y/palette-add-aria-labels
#   refactor/sweeper-simplify-parser
```

### Step 4: Implementation & Verification
The agent applies the changes, ensuring backward compatibility, and runs local test and lint suites:
```bash
# Typical verification commands:
make fmt && make lint && make test
# Or npm/pnpm equivalents:
pnpm lint && pnpm test
```

### Step 5: Conditional Journal Reflection
Only if a critical codebase-specific pattern or pitfall was discovered, the agent appends a structured entry to `.jules/<agent>.md`:
```markdown
## YYYY-MM-DD - [Title]
**Learning:** [Insight specific to this codebase]
**Action:** [How to apply next time]
```
If no novel insight was discovered, the journal must **NOT** be touched.

### Step 6: Atomic Commit
All modified files (including the journal if updated) are committed together in a single atomic commit:
```bash
git add -A && git commit -m "<type>(<scope>): <description>"
```

### Step 7: Push & Pull Request
The agent pushes the branch and creates a Pull Request with a clear summary:
- **What**: The specific improvement made.
- **Why**: The problem it resolves.
- **Impact / Verification**: Steps taken to verify functionality and performance/security impact.

---

## 4. Coding & Development Standards

- **Language & Runtime**: Go 1.25+, standard library idioms.
- **Structured Logging**: Use `log/slog` or structured standard output. Avoid raw unstructured prints for errors.
- **Error Handling**: Wrap errors with context using `fmt.Errorf("operation failed: %w", err)`.
- **LocalHarness Integration**: Always reference `localharnessVersion = "0.4.0"` in `agents/agents.go`.
- **Verification Commands**: Before committing changes to this repository, always run:
  ```bash
  make fmt && make lint && make test && make build
  ```

---

## 5. Versioning & Conventional Commits

This repository enforces **Conventional Commits** integrated with [Release Please](https://github.com/googleapis/release-please):

| Commit Prefix | SemVer Impact | Description |
| :--- | :--- | :--- |
| `feat:` | **MINOR** | Introduces a new feature or agent capability |
| `fix:` | **PATCH** | Fixes a bug or unexpected behavior |
| `perf:` | **PATCH** | Improves performance without adding features |
| `docs:` | None | Documentation updates |
| `refactor:` | None | Code refactoring without behavioral change |
| `chore:` | None | Build, CI/CD, dependencies, or maintenance |
| `feat!:` / `BREAKING CHANGE:` | **MAJOR** | Breaking change to CLI or API interface |

---

## 6. Living Product Roadmap Lifecycle

This repository maintains a living product roadmap in [ROADMAP.md](ROADMAP.md):
- **Adding Items**: When identifying future capabilities, enhancements, or architectural debt, add an entry to [ROADMAP.md](ROADMAP.md).
- **Pruning Items**: When a roadmap item is implemented and verified, remove it from [ROADMAP.md](ROADMAP.md) immediately.
