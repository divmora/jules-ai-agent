# Jules Product Roadmap

This document serves as the **living product roadmap** for Jules AI Agent.
- **Adding Items**: Whenever a new capability, enhancement, or architectural improvement is identified for future work, add it here under the appropriate category.
- **Removing Items**: Once a feature is fully implemented, verified with tests, and committed, **remove it from this roadmap**.

---

## 1. Agent Capabilities & Intelligence

- [ ] **Interactive Consensus Review Mode**
  - Enable multi-agent reviews where Sentinel, Bolt, Palette, and Sweeper sequentially review changes and form a unified review summary.
- [ ] **AST-Guided Scope Slicing**
  - Implement language-aware abstract syntax tree parsing to narrow the agent's context focus to affected callers and call-graphs.
- [ ] **Self-Healing Test Execution Loop**
  - Allow agents to iteratively fix failing test suites when regressions are introduced during code modifications.

---

## 2. Developer Experience & Integration

- [ ] **GitLab CI/CD Component Integration**
  - Package Jules as a reusable GitLab CI/CD component for native scheduled pipeline execution.
- [ ] **GitHub Action Wrapper**
  - Provide a turnkey composite GitHub Action for triggering Jules on pull request creation or daily cron triggers.
- [ ] **Custom Agent Archetype Generator**
  - CLI command (`jules init-agent`) allowing teams to scaffold custom domain agents with customized guidelines and subagents.

---

## 3. Runtime & Tooling

- [ ] **Configurable Diff Size Caps**
  - Allow configuring max diff lines (default 50 lines) via CLI flag `--max-diff-lines`.
- [ ] **Structured SARIF Output Export**
  - Emit findings in standard SARIF format for ingestion into GitHub Security or GitLab Vulnerability Reports.
