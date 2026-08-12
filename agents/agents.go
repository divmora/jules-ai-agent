// Package agents defines the three Jules AI review agents.
//
// Each agent is configured with a specialized identity and structured prompt
// tuned for its domain (performance, design, security). All agents share the
// same workspace and run a single analysis pass before auto-stopping.
//
// Agents:
//   - Bolt ⚡  — performance issues (see [NewBoltConfig])
//   - Palette 🎨 — design issues (see [NewPaletteConfig])
//   - Sentinel 🛡️ — security issues (see [NewSentinelConfig])
package agents

import (
	"github.com/divmora/localharness/adk"
	"github.com/divmora/localharness/adk/policy"
)

// newBaseConfig returns a LocalAgentConfig with shared defaults for all agents.
//
// v0.4.0 enhancements:
//   - MaxSubagentDepth=1: agents can spawn one level of research subagents
//   - MaxAutoWakeTurns=5: safety cap on autonomous turns
//
// NOTE: EnablePlanningMode is OFF — see comment in function body.
func newBaseConfig(workspace string) *adk.LocalAgentConfig {
	cfg := adk.NewLocalAgentConfig()
	cfg.Workspaces = []adk.WorkspaceDef{{Directory: workspace}}
	cfg.Policies = []policy.Policy{policy.AllowAll()}
	cfg.Capabilities.RunCommand = true

	// NOTE: EnablePlanningMode is intentionally OFF. The plan-before-act
	// workflow requires writing to the brain directory, which is outside the
	// workspace. The auto-prepended workspace_only policy blocks this, causing
	// a permission-denied loop. These are single-shot analysis agents that
	// don't need the planning workflow.

	// Allow one level of subagents for research/analysis delegation
	cfg.MaxSubagentDepth = 1
	cfg.MaxConcurrentSubagents = 3

	// Safety: cap autonomous background turns to prevent runaway loops
	cfg.MaxAutoWakeTurns = 5

	return cfg
}
