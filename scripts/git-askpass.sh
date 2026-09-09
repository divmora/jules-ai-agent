#!/bin/sh
# ============================================================================
# git-askpass.sh — GIT_ASKPASS credential helper
# ============================================================================
# Provides HTTPS credentials to git when cloning private repositories.
# Git calls this script with a prompt ("Username for ..." or "Password for ...")
# and expects the appropriate value on stdout.
#
# This script is provider-agnostic — it works with GitLab, GitHub, Bitbucket,
# and any git host that accepts token-as-password over HTTPS.
#
# Usage:
#   Export GIT_ASKPASS pointing to this script. Git calls it automatically.
#   Do NOT call this script directly.
#
# Environment Variables:
#   GIT_HTTPS_TOKEN  — HTTPS access token (required)
#   GIT_HTTPS_USER   — Username for token auth (default: "oauth2")
#
# Provider-specific usernames:
#   GitLab / Self-hosted GitLab:  oauth2          (default)
#   GitHub:                       x-access-token
#   Bitbucket:                    x-token-auth
#
# Exit Codes:
#   0 — Success
#   1 — Missing token / invalid usage
# ============================================================================

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    sed -n '2,/^# ====/{ /^# ====/d; s/^# \{0,1\}//; p }' "$0"
    exit 0
fi

# Git passes the prompt as $1 (e.g., "Username for 'https://gitlab.com': ")
case "${1:-}" in
    Username*)
        echo "${GIT_HTTPS_USER:-oauth2}"
        ;;
    Password*)
        if [ -z "${GIT_HTTPS_TOKEN:-}" ]; then
            echo "git-askpass.sh: GIT_HTTPS_TOKEN is not set" >&2
            exit 1
        fi
        echo "${GIT_HTTPS_TOKEN}"
        ;;
    *)
        echo "git-askpass.sh: unexpected prompt: ${1:-}" >&2
        exit 1
        ;;
esac
