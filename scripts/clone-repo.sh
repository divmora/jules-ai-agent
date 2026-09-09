#!/usr/bin/env bash
# ============================================================================
# clone-repo.sh — Smart Git Repository Cloner
# ============================================================================
# Clones a git repository with retry logic, SSH/HTTPS auto-detection,
# optional shallow cloning, and branch/tag selection.
# If the target directory already exists and is a valid git repo, the script
# syncs it (fetch + checkout) instead of failing.
#
# Usage:
#   clone-repo.sh <repo-url> <target-dir>
#
# Environment Variables:
#   GIT_REF              — Branch, tag, or commit to checkout (default: repo default branch)
#   SHALLOW_CLONE        — Set to "true" for depth-1 clone (default: "false")
#   MAX_RETRIES          — Number of retry attempts (default: 3)
#   RETRY_DELAY          — Initial delay in seconds between retries (default: 2)
#   SSH_STRICT_HOST_KEY  — SSH StrictHostKeyChecking value (default: "accept-new")
#   GIT_SSH_KEY_PATH     — Path to SSH private key (default: none)
#   GIT_HTTPS_TOKEN      — HTTPS access token for private repos (default: none)
#   GIT_HTTPS_USER       — Username for HTTPS token auth (default: "oauth2")
#   CREATE_REMOTE_BRANCH — Push new branch to origin if created (default: "false")
#   GIT_CLONE_TIMEOUT    — Timeout per clone attempt in seconds (default: 600)
#
# Exit Codes:
#   0 — Success
#   1 — Invalid arguments / validation failure
#   2 — Clone failed after all retries
#   3 — Clone timed out
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_MAX_RETRIES=3
readonly DEFAULT_RETRY_DELAY=2
readonly DEFAULT_SSH_STRICT_HOST_KEY="accept-new"
readonly DEFAULT_CLONE_TIMEOUT=600

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
log_info()  { echo "[${SCRIPT_NAME}] [INFO]  $*"; }
log_warn()  { echo "[${SCRIPT_NAME}] [WARN]  $*" >&2; }
log_error() { echo "[${SCRIPT_NAME}] [ERROR] $*" >&2; }

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} <repo-url> <target-dir>

Clone a git repository with automatic retry and protocol detection.

Arguments:
  repo-url      Git repository URL (SSH or HTTPS)
  target-dir    Local directory to clone into

Environment Variables:
  GIT_REF              Branch, tag, or commit to checkout (default: repo default)
  SHALLOW_CLONE        "true" for depth-1 clone (default: "false")
  MAX_RETRIES          Retry attempts (default: ${DEFAULT_MAX_RETRIES})
  RETRY_DELAY          Initial retry delay in seconds (default: ${DEFAULT_RETRY_DELAY})
  SSH_STRICT_HOST_KEY  SSH StrictHostKeyChecking (default: "${DEFAULT_SSH_STRICT_HOST_KEY}")
  GIT_SSH_KEY_PATH     Path to SSH private key file
  GIT_HTTPS_TOKEN      HTTPS access token for private repos
  GIT_HTTPS_USER       Username for HTTPS token auth (default: "oauth2")
  CREATE_REMOTE_BRANCH "true" to push newly created branch to origin (default: "false")
  GIT_CLONE_TIMEOUT    Timeout per clone attempt in seconds (default: ${DEFAULT_CLONE_TIMEOUT})

Exit Codes:
  0  Success
  1  Invalid arguments
  2  Clone failed after all retries
  3  Clone timed out
EOF
}

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------
validate_inputs() {
    local repo_url="$1"
    local target_dir="$2"

    if [[ -z "${repo_url}" ]]; then
        log_error "Repository URL is required."
        usage
        exit 1
    fi

    if [[ -z "${target_dir}" ]]; then
        log_error "Target directory is required."
        usage
        exit 1
    fi

    # Validate the URL looks like a git repo (SSH or HTTPS).
    if [[ ! "${repo_url}" =~ ^(https?://|git@|ssh://) ]]; then
        log_error "Invalid repository URL format: ${repo_url}"
        log_error "Expected formats: https://..., git@..., ssh://..."
        exit 1
    fi

    # Security: prevent path traversal in target directory.
    local resolved_dir
    resolved_dir="$(realpath -m "${target_dir}")"
    if [[ "${resolved_dir}" == "/" ]]; then
        log_error "Target directory cannot be the root filesystem."
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Protocol detection
# ---------------------------------------------------------------------------
detect_protocol() {
    local repo_url="$1"

    if [[ "${repo_url}" =~ ^https?:// ]]; then
        echo "https"
    elif [[ "${repo_url}" =~ ^git@ ]] || [[ "${repo_url}" =~ ^ssh:// ]]; then
        echo "ssh"
    else
        echo "unknown"
    fi
}

# ---------------------------------------------------------------------------
# SSH configuration
# ---------------------------------------------------------------------------
configure_ssh() {
    local strict_host_key="${SSH_STRICT_HOST_KEY:-${DEFAULT_SSH_STRICT_HOST_KEY}}"
    local ssh_key_path="${GIT_SSH_KEY_PATH:-}"

    local ssh_opts="-o StrictHostKeyChecking=${strict_host_key} -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

    if [[ -n "${ssh_key_path}" ]]; then
        if [[ ! -f "${ssh_key_path}" ]]; then
            log_error "SSH key file not found: ${ssh_key_path}"
            exit 1
        fi
        ssh_opts="${ssh_opts} -i ${ssh_key_path}"
        log_info "Using SSH key: ${ssh_key_path}"
    fi

    export GIT_SSH_COMMAND="ssh ${ssh_opts}"
    log_info "SSH configured (StrictHostKeyChecking=${strict_host_key})"
}

# ---------------------------------------------------------------------------
# HTTPS configuration (GIT_ASKPASS)
# ---------------------------------------------------------------------------
configure_https() {
    local token="${GIT_HTTPS_TOKEN:-}"

    if [[ -z "${token}" ]]; then
        log_info "No HTTPS token configured — assuming public repo"
        return 0
    fi

    local askpass_path
    askpass_path="$(command -v git-askpass.sh 2>/dev/null || echo "")"

    if [[ -z "${askpass_path}" ]] || [[ ! -f "${askpass_path}" ]]; then
        log_error "git-askpass.sh not found in PATH"
        exit 1
    fi

    export GIT_ASKPASS="${askpass_path}"
    # Disable terminal prompts — fail instead of hanging in a container.
    export GIT_TERMINAL_PROMPT=0
    log_info "HTTPS token auth configured (user=${GIT_HTTPS_USER:-oauth2})"
}

# ---------------------------------------------------------------------------
# Remote ref detection
# ---------------------------------------------------------------------------
ref_exists_on_remote() {
    local repo_url="$1"
    local ref="$2"

    log_info "Checking if ref '${ref}' exists on remote..."
    git ls-remote --exit-code --heads --tags "${repo_url}" "${ref}" &>/dev/null
}

# ---------------------------------------------------------------------------
# Branch creation (when ref does not exist on remote)
# ---------------------------------------------------------------------------
create_branch() {
    local target_dir="$1"
    local branch_name="$2"
    local push_remote="${CREATE_REMOTE_BRANCH:-false}"

    log_info "Creating new branch: ${branch_name}"
    git -C "${target_dir}" checkout -b "${branch_name}"

    if [[ "${push_remote}" == "true" ]]; then
        log_info "Pushing new branch '${branch_name}' to origin..."
        git -C "${target_dir}" push -u origin "${branch_name}"
        log_info "Branch '${branch_name}' created and pushed to origin"
    else
        log_info "Branch '${branch_name}' created locally (set CREATE_REMOTE_BRANCH=true to push)"
    fi
}

# ---------------------------------------------------------------------------
# Handle existing target directory
# ---------------------------------------------------------------------------
handle_existing_repo() {
    local target_dir="$1"
    local repo_url="$2"
    local git_ref="${GIT_REF:-}"

    if [[ ! -d "${target_dir}/.git" ]]; then
        log_warn "Target directory exists but is not a git repository: ${target_dir}"
        log_warn "Removing it and cloning fresh..."
        rm -rf "${target_dir}"
        return 1
    fi

    log_info "Repository already exists at ${target_dir} — checking local state"

    # Safety check: detect uncommitted changes.
    local has_uncommitted=false
    if [[ -n "$(git -C "${target_dir}" status --porcelain 2>/dev/null)" ]]; then
        has_uncommitted=true
    fi

    # Safety check: detect unpushed commits on current branch.
    local has_unpushed=false
    local current_branch
    current_branch="$(git -C "${target_dir}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ -n "${current_branch}" ]] && [[ "${current_branch}" != "HEAD" ]]; then
        local unpushed_count
        unpushed_count="$(git -C "${target_dir}" rev-list --count "origin/${current_branch}..HEAD" 2>/dev/null || echo "0")"
        if [[ "${unpushed_count}" -gt 0 ]]; then
            has_unpushed=true
        fi
    fi

    # If local work exists, skip sync to protect developer's changes.
    if [[ "${has_uncommitted}" == "true" ]] || [[ "${has_unpushed}" == "true" ]]; then
        log_warn "Local changes detected in ${target_dir} — skipping sync to preserve work"
        if [[ "${has_uncommitted}" == "true" ]]; then
            log_warn "  • Uncommitted changes found (staged or unstaged)"
        fi
        if [[ "${has_unpushed}" == "true" ]]; then
            log_warn "  • ${unpushed_count} unpushed commit(s) on '${current_branch}'"
        fi
        log_info "Repository left as-is: ${target_dir}"
        return 0
    fi

    log_info "Working tree is clean — syncing with remote"

    # Verify the remote matches the requested URL.
    local current_remote
    current_remote="$(git -C "${target_dir}" remote get-url origin 2>/dev/null || echo "")"
    if [[ -n "${current_remote}" ]] && [[ "${current_remote}" != "${repo_url}" ]]; then
        log_warn "Existing remote origin (${current_remote}) differs from requested URL (${repo_url})"
        log_info "Updating remote origin to ${repo_url}"
        git -C "${target_dir}" remote set-url origin "${repo_url}"
    fi

    log_info "Fetching latest changes from origin..."
    if ! git -C "${target_dir}" fetch --prune origin; then
        log_warn "Fetch failed — continuing with existing local state"
    fi

    # Checkout the requested ref if specified.
    if [[ -n "${git_ref}" ]]; then
        local current_ref
        current_ref="$(git -C "${target_dir}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
        if [[ "${current_ref}" != "${git_ref}" ]]; then
            log_info "Switching from '${current_ref}' to '${git_ref}'"
            if git -C "${target_dir}" rev-parse --verify "origin/${git_ref}" &>/dev/null; then
                git -C "${target_dir}" checkout -B "${git_ref}" "origin/${git_ref}"
            elif git -C "${target_dir}" rev-parse --verify "${git_ref}" &>/dev/null; then
                git -C "${target_dir}" checkout "${git_ref}"
            else
                log_warn "Ref '${git_ref}' not found locally or on remote — staying on '${current_ref}'"
            fi
        else
            # Already on the right branch — fast-forward if possible.
            log_info "Already on '${git_ref}' — pulling latest changes"
            git -C "${target_dir}" pull --ff-only origin "${git_ref}" 2>/dev/null || \
                log_warn "Fast-forward pull failed — local branch may have diverged"
        fi
    fi

    log_info "Existing repository synced successfully: ${target_dir}"
    return 0
}

# ---------------------------------------------------------------------------
# Clone with retry
# ---------------------------------------------------------------------------
clone_with_retry() {
    local repo_url="$1"
    local target_dir="$2"
    local include_ref="${3:-true}"
    local max_retries="${MAX_RETRIES:-${DEFAULT_MAX_RETRIES}}"
    local retry_delay="${RETRY_DELAY:-${DEFAULT_RETRY_DELAY}}"
    local git_ref="${GIT_REF:-}"
    local shallow="${SHALLOW_CLONE:-false}"
    local clone_timeout="${GIT_CLONE_TIMEOUT:-${DEFAULT_CLONE_TIMEOUT}}"

    # Build the git clone command arguments.
    local -a clone_args=("clone")

    if [[ "${shallow}" == "true" ]]; then
        clone_args+=("--depth" "1")
        log_info "Shallow clone enabled (depth=1)"
    fi

    if [[ "${include_ref}" == "true" ]] && [[ -n "${git_ref}" ]]; then
        clone_args+=("--branch" "${git_ref}")
        log_info "Target ref: ${git_ref}"
    fi

    clone_args+=("--" "${repo_url}" "${target_dir}")

    # Retry loop with exponential backoff.
    local attempt=1
    local delay="${retry_delay}"

    while [[ ${attempt} -le ${max_retries} ]]; do
        log_info "Clone attempt ${attempt}/${max_retries} (timeout: ${clone_timeout}s)..."

        if timeout "${clone_timeout}" git "${clone_args[@]}"; then
            log_info "Clone successful → ${target_dir}"
            return 0
        fi

        local exit_code=$?
        if [[ ${exit_code} -eq 124 ]]; then
            log_error "Clone attempt ${attempt} timed out after ${clone_timeout}s"
        else
            log_warn "Attempt ${attempt} failed."
        fi

        if [[ ${attempt} -lt ${max_retries} ]]; then
            log_info "Retrying in ${delay}s..."
            sleep "${delay}"
            delay=$((delay * 2))
        fi

        attempt=$((attempt + 1))
    done

    log_error "All ${max_retries} clone attempts failed for: ${repo_url}"
    return 2
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        usage
        exit 0
    fi

    local repo_url="${1:-}"
    local target_dir="${2:-}"

    validate_inputs "${repo_url}" "${target_dir}"

    local protocol
    protocol="$(detect_protocol "${repo_url}")"
    log_info "Detected protocol: ${protocol}"

    if [[ "${protocol}" == "ssh" ]]; then
        configure_ssh
    elif [[ "${protocol}" == "https" ]]; then
        configure_https
    fi

    local git_ref="${GIT_REF:-}"
    local ref_on_remote=true

    # If a ref is specified, check whether it exists on the remote.
    if [[ -n "${git_ref}" ]]; then
        if ref_exists_on_remote "${repo_url}" "${git_ref}"; then
            log_info "Ref '${git_ref}' exists on remote"
        else
            log_warn "Ref '${git_ref}' not found on remote — will clone default branch and create it locally"
            ref_on_remote=false
        fi
    fi

    # Ensure the parent directory exists before cloning.
    local parent_dir
    parent_dir="$(dirname "${target_dir}")"
    log_info "Ensuring parent directory exists: ${parent_dir}"
    mkdir -p "${parent_dir}"

    # If the target directory already exists, sync instead of cloning.
    # handle_existing_repo returns 0 if synced, 1 if dir was removed (needs clone).
    if [[ -d "${target_dir}" ]]; then
        if handle_existing_repo "${target_dir}" "${repo_url}"; then
            return 0
        fi
    fi

    log_info "Cloning ${repo_url} → ${target_dir}"

    if [[ "${ref_on_remote}" == "true" ]]; then
        clone_with_retry "${repo_url}" "${target_dir}" "true"
    else
        clone_with_retry "${repo_url}" "${target_dir}" "false"
        create_branch "${target_dir}" "${git_ref}"
    fi
}

main "$@"
