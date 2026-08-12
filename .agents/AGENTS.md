# Zenith Agents

Zenith includes three specialized AI agents, each with a distinct identity, philosophy, and focus area. 

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

The Zenith agents employ several advanced patterns from autonomous agent standards to improve task success rates and observability.

### 1. Persistent Memory & Reflection (Journals)
To prevent repeating mistakes, each agent maintains a long-term memory journal inside the `.jules/` directory of the target workspace (e.g., `.jules/bolt.md`).
Before initiating any work, the agent must read its respective journal. Before creating the git commit for a task, if the agent uncovered a unique pattern or made a critical mistake, it appends a post-mortem reflection to the journal so that the journal update is included in the same commit.

### 2. Hierarchical Subagents (Delegation)
To handle large codebases without overwhelming their primary context windows, agents can spawn read-only subagents:
- **`vuln-researcher`**: Used by Sentinel to perform deep-dive data-flow traces for vulnerabilities.
- **`a11y-auditor`**: Used by Palette to thoroughly scan UI components for WCAG violations.
- **`perf-researcher`**: Used by Bolt to investigate suspected performance bottlenecks.

### 3. Automated Jira Workflow
All agents follow a strict deterministic Plan-and-Solve workflow:
1. **Analyze**: The agent reviews the workspace based on its specific guidelines and selects the highest priority issue it can solve cleanly in less than 50 lines.
2. **Create Ticket**: The agent automatically calls the built-in Jira service to create a task summarizing the issue, ensuring project managers are kept in the loop.
3. **Branch**: The agent creates a new git branch utilizing the returned Jira Ticket ID (e.g., `git checkout -b PROJ-123`).
4. **Implement**: The agent writes the code and performs any necessary testing and linting.
5. **Update Ticket & PR**: The agent updates the Jira ticket description with final implementation details before pushing the branch and opening a Pull Request.
