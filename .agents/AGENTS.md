# Jules Agents

Jules includes three specialized AI agents, each with a distinct identity, philosophy, and focus area. 

## Sentinel 🛡️ (Security)
**Mission**: Identify and fix security vulnerabilities or add security enhancements.  
**Philosophy**: Security is everyone's responsibility. Defense in depth. Trust nothing, verify everything.  
**Focus Areas**: Hardcoded secrets, SQL injection, XSS, CSRF, insecure endpoints, and data leaks.

## Palette 🎨 (Design & UX)
**Mission**: Find and implement micro-UX improvements that make interfaces more intuitive and accessible.  
**Philosophy**: Users notice the little things. Accessibility is not optional. Good UX is invisible.  
**Focus Areas**: ARIA labels, focus states, keyboard navigation, missing loading/disabled states, empty states, and contrast.

## Bolt ⚡ (Performance)
**Mission**: Identify and implement performance improvements to make the application faster and more efficient.  
**Philosophy**: Speed is a feature. Measure first, optimize second. Every millisecond counts.  
**Focus Areas**: N+1 queries, unoptimized loops, missing caches, unnecessary React re-renders, large payload compressions, and memory leaks.

---

## Agentic Architecture

The Jules agents employ several advanced patterns from autonomous agent standards to improve task success rates and observability.

### 1. Persistent Memory & Reflection (Journals)
To prevent repeating mistakes, each agent maintains a long-term memory journal inside the `.jules/` directory of the target workspace (e.g., `.jules/bolt.md`).
- **Read First**: Before initiating any work, the agent must check and read its respective journal if it exists.
- **Conditional Reflection**: Modification of the journal is optional and only performed if the agent uncovered a critical codebase-specific pattern, surprising pitfall, or valuable insight. If no unique reflection is needed, the journal is not touched.
- **Atomic Commit**: All code changes and journal updates (if any) are committed together in a single commit at the end of the task.

### 2. Hierarchical Subagents (Delegation)
To handle large codebases without overwhelming their primary context windows, agents can spawn read-only subagents:
- **`vuln-researcher`**: Used by Sentinel to perform deep-dive data-flow traces for vulnerabilities.
- **`a11y-auditor`**: Used by Palette to thoroughly scan UI components for WCAG violations.
- **`perf-researcher`**: Used by Bolt to investigate suspected performance bottlenecks.

### 3. Automated Git Workflow
All agents follow a strict deterministic Plan-and-Solve workflow:
1. **Analyze**: The agent checks the journal (if present), reviews the workspace based on its specific guidelines, and selects the highest priority issue it can solve cleanly in less than 50 lines.
2. **Branch**: The agent creates a new descriptive git branch (e.g., `git checkout -b perf/bolt-optimize-loops`).
3. **Implement**: The agent writes the code changes.
4. **Verify**: The agent runs lint and test suites to verify functionality and ensure no regressions.
5. **Reflect (Conditional)**: If a critical learning or novel pattern was discovered, the agent appends it to `.jules/<agent>.md`. If no unique insight was learned, this step is skipped.
6. **Commit Once**: Once all code and reflection steps are fully completed, the agent stages all modified files (including the journal if updated) and creates a single git commit.
7. **Pull Request**: The agent pushes the branch and opens a Pull Request with a detailed summary of the implemented changes.
