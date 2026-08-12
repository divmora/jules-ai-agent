// Jules — AI-powered code review agents.
//
// Run one of three specialised agents (Bolt, Palette, Sentinel) against a
// workspace to find performance, design, or security issues respectively.
//
// Usage:
//
//	go run . --agent bolt     --workspace ./myproject --prompt "Analyse the codebase for performance issues"
//	go run . --agent palette  --workspace ./myproject --prompt "Review the architecture"
//	go run . --agent sentinel --workspace ./myproject --prompt "Audit for security vulnerabilities"
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/divmora/jules-ai-agent/agents"
	"github.com/divmora/localharness/adk"
)

func main() {
	agentName := flag.String("agent", "", "Agent to run: bolt (performance), palette (design), sentinel (security)")
	workspace := flag.String("workspace", ".", "Workspace directory to analyse")
	prompt := flag.String("prompt", "", "Prompt to send to the agent")
	verbose := flag.Bool("verbose", false, "Enable verbose/debug logging from the agent")
	flag.Parse()

	// --- Validate inputs ---

	if *agentName == "" {
		fmt.Fprintln(os.Stderr, "Error: --agent is required (bolt, palette, sentinel)")
		flag.Usage()
		os.Exit(1)
	}

	if *prompt == "" {
		fmt.Fprintln(os.Stderr, "Error: --prompt is required")
		flag.Usage()
		os.Exit(1)
	}



	// Resolve workspace to absolute path
	absWorkspace, err := filepath.Abs(*workspace)
	if err != nil {
		log.Fatalf("Failed to resolve workspace path: %v", err)
	}

	// --- Pick agent config ---

	var cfg *adk.LocalAgentConfig

	switch strings.ToLower(*agentName) {
	case "bolt":
		cfg = agents.NewBoltConfig(absWorkspace)
		fmt.Println("⚡ Starting Bolt — Performance Agent")
	case "palette":
		cfg = agents.NewPaletteConfig(absWorkspace)
		fmt.Println("🎨 Starting Palette — Design Agent")
	case "sentinel":
		cfg = agents.NewSentinelConfig(absWorkspace)
		fmt.Println("🛡️  Starting Sentinel — Security Agent")
	default:
		fmt.Fprintf(os.Stderr, "Error: unknown agent %q (valid: bolt, palette, sentinel)\n", *agentName)
		os.Exit(1)
	}

	// Enable verbose logging if requested
	if *verbose {
		cfg.Verbose = true
	}

	fmt.Printf("   Workspace: %s\n", absWorkspace)
	fmt.Printf("   Prompt:    %s\n", *prompt)
	fmt.Printf("   Verbose:   %v\n\n", *verbose)

	// --- Run agent (single-shot, streaming for live output) ---

	ctx := context.Background()

	agent, err := adk.NewAgent(cfg)
	if err != nil {
		log.Fatalf("Failed to create agent: %v", err)
	}
	defer agent.Close()

	if err := agent.Start(ctx); err != nil {
		log.Fatalf("Failed to start agent: %v", err)
	}

	// Use streaming so we see real-time output
	events, err := agent.ChatStream(ctx, *prompt)
	if err != nil {
		log.Fatalf("Failed to start chat: %v", err)
	}

	fmt.Println("─────────────────────────────────────────")

	var resp *adk.ChatResponse
	for event := range events {
		switch event.Type {
		case adk.EventTextDelta:
			fmt.Print(event.TextDelta)
		case adk.EventToolCallStart:
			fmt.Printf("\n🔧 Tool: %s\n", event.Step.ToolName)
		case adk.EventToolCallDone:
			fmt.Println("   ✅ done")
		case adk.EventError:
			fmt.Printf("   ❌ Error: %s\n", event.Step.ErrorMessage)
		case adk.EventTurnComplete:
			resp = event.Response
			if event.Error != nil {
				log.Printf("Turn completed with error: %v", event.Error)
			}
		}
	}

	fmt.Println("\n─────────────────────────────────────────")

	if resp != nil && resp.Usage != nil {
		fmt.Printf("\n📊 Tokens — prompt: %d, completion: %d, total: %d\n",
			resp.Usage.PromptTokens,
			resp.Usage.CompletionTokens,
			resp.Usage.TotalTokens,
		)
	}

	fmt.Println("\n✅ Agent finished. Exiting.")
}
