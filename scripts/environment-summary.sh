#!/usr/bin/env bash
# ============================================================================
# environment-summary.sh — Print installed toolchain versions
# ============================================================================
# Displays a formatted summary of all languages, runtimes, and CLI tools
# installed in the Jules workspace container.
#
# Usage:
#   environment-summary.sh
#
# Exit Codes:
#   0 — Always succeeds (missing tools are reported as warnings)
# ============================================================================

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
    echo "Usage: ${SCRIPT_NAME}"
    echo "Print installed toolchain versions in the workspace container."
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# Print a version line, or a warning if the command is missing.
print_version() {
    local name="$1"
    local version="$2"
    printf "  ✅ %-12s %s\n" "${name}" "${version}"
}

print_missing() {
    local name="$1"
    printf "  ⚠️  %-12s %s\n" "${name}" "(not found)"
}

check_tool() {
    local name="$1"
    local cmd="$2"
    if command -v "${cmd}" > /dev/null 2>&1; then
        local ver
        ver=$(eval "$3" 2>&1 || true)
        print_version "${name}" "${ver}"
    else
        print_missing "${name}"
    fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ubuntu-noble-systemd-docker — Environment Summary"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "──── Node.js ────"
check_tool "node"    "node"    "node -v"
check_tool "npm"     "npm"     "npm -v"
check_tool "yarn"    "yarn"    "yarn -v"
check_tool "pnpm"    "pnpm"    "pnpm -v"
echo ""

echo "──── Python ────"
check_tool "python3" "python3" "python3 --version | cut -d' ' -f2"
check_tool "pip"     "pip3"    "pip3 --version | cut -d' ' -f2"
check_tool "poetry"  "poetry"  "poetry --version | cut -d' ' -f3"
echo ""

echo "──── Go ────"
check_tool "go"      "go"      "go version | cut -d' ' -f3"
echo ""

echo "──── PHP ────"
check_tool "php"       "php"       "php -v | head -n1 | cut -d' ' -f2"
check_tool "composer"  "composer"  "composer --version | cut -d' ' -f3"
check_tool "phpcs"     "phpcs"     "phpcs --version | cut -d' ' -f3"
check_tool "phpcbf"    "phpcbf"    "phpcbf --version | cut -d' ' -f3"
echo ""

echo "──── C/C++ ────"
check_tool "gcc"     "gcc"     "gcc --version | head -n1 | rev | cut -d' ' -f1 | rev"
check_tool "make"    "make"    "make --version | head -n1 | cut -d' ' -f3"
echo ""

echo "──── Docker ────"
check_tool "docker"  "docker"  "docker -v | cut -d' ' -f3 | tr -d ','"
check_tool "compose" "docker"  "docker compose version 2>/dev/null | cut -d' ' -f4"
echo ""

echo "──── Utilities ────"
check_tool "curl"    "curl"    "curl --version | head -n1 | cut -d' ' -f2"
check_tool "git"     "git"     "git --version | cut -d' ' -f3"
check_tool "jq"      "jq"     "jq --version | tr -d '\"'"
check_tool "rg"      "rg"     "rg --version | head -n1 | cut -d' ' -f2"
check_tool "tmux"    "tmux"   "tmux -V | cut -d' ' -f2"
check_tool "yq"      "yq"     "yq --version | cut -d' ' -f4"
check_tool "nginx"   "nginx"  "nginx -v 2>&1 | cut -d'/' -f2"
echo ""
echo "═══════════════════════════════════════════"
