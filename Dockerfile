# ---------------------------------------------------------------------------
# Stage 1: Build Jules and Localharness
# ---------------------------------------------------------------------------
FROM golang:1.25-bookworm AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

RUN GOPROXY=direct CGO_ENABLED=0 GOOS=linux go install github.com/divmora/localharness/cmd/localharness@main

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /jules .

# ============================================================================
# Jules Workspace Images — Ubuntu Noble + systemd + Docker
# ----------------------------------------------------------------------------
# Complete interactive developer workspace runtime for GitLab Remote
# Development. Includes Node.js, Python, Go, and Docker
# toolchains with package managers and CLI utilities.
# Runs systemd as PID 1 for service management.
#
# Base: Ubuntu 24.04 LTS (Noble Numbat)
# ============================================================================

FROM ubuntu:24.04

# OCI Image Labels
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION="dev"

LABEL org.opencontainers.image.title="jules-ubuntu-noble-systemd-docker" \
    org.opencontainers.image.description="Full developer workspace with Node.js 22, Python 3.12, Go, PHP 8.4, and Docker for GitLab Remote Development" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.source="https://github.com/divmora/jules-ai-agent" \
    org.opencontainers.image.vendor="Zenith" \
    org.opencontainers.image.base.name="ubuntu:24.04"

# Prevent interactive prompts during package installation.
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# 1. System packages, systemd & locale
# ---------------------------------------------------------------------------
# Core utilities, developer tools, build essentials, and systemd for service
# management (Docker auto-starts via systemd unit).
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Locale support
    locales \
    # Init system — required for Docker service auto-start
    systemd \
    systemd-sysv \
    # Core utilities
    bc \
    ca-certificates \
    curl \
    gawk \
    gettext-base \
    gnupg \
    gzip \
    tar \
    wget \
    # Developer tools
    build-essential \
    git \
    htop \
    jq \
    nano \
    openssh-client \
    ripgrep \
    software-properties-common \
    tmux \
    unzip \
    vim \
    zip \
    && locale-gen en_US.UTF-8 \
    # Clean up unnecessary systemd units that cause noise in containers.
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    && rm -f /lib/systemd/system/systemd-update-utmp* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ---------------------------------------------------------------------------
# 2. Docker CE (Docker-in-Docker support)
# ---------------------------------------------------------------------------
# Docker daemon auto-starts via systemd when the container boots.
# Container must run with --privileged for Docker-in-Docker.
# hadolint ignore=DL3008
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Enable Docker service so systemd starts it automatically.
    && systemctl enable docker

# Store Docker data on a separate path to avoid overlay-on-overlay issues.
RUN mkdir -p /etc/docker /opt/docker_data \
    && printf '{\n  "data-root": "/opt/docker_data"\n}\n' \
    > /etc/docker/daemon.json

# ---------------------------------------------------------------------------
# 3. Node.js 22 LTS (via NodeSource)
# ---------------------------------------------------------------------------
# hadolint ignore=DL3008,DL3016
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@latest yarn pnpm eslint prettier \
    && node --version && npm --version

# ---------------------------------------------------------------------------
# 4. Python 3.12 + Poetry
# ---------------------------------------------------------------------------
# hadolint ignore=DL3008,DL3013
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSL https://install.python-poetry.org | python3 - \
    && python3 --version && pip3 --version

# ---------------------------------------------------------------------------
# 5. Go (latest 1.26.x)
# ---------------------------------------------------------------------------
ARG TARGETARCH
ARG GO_VERSION="1.26.2"
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
    -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz \
    && /usr/local/go/bin/go version

# ---------------------------------------------------------------------------
# 6. CLI tools (yq)
# ---------------------------------------------------------------------------
# Using wget here instead of curl for simpler GitHub release redirect handling.
ARG TARGETARCH
RUN wget -q "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${TARGETARCH}" \
    -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && yq --version

# ---------------------------------------------------------------------------
# 7. Nginx
# ---------------------------------------------------------------------------
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && systemctl enable nginx

# ---------------------------------------------------------------------------
# 8. PHP 8.4 + Composer
# ---------------------------------------------------------------------------
# hadolint ignore=DL3008,DL3015
RUN add-apt-repository ppa:ondrej/php -y \
    && apt-get update && apt-get install -y --no-install-recommends \
    php8.4 \
    php8.4-cli \
    php8.4-common \
    php8.4-curl \
    php8.4-mbstring \
    php8.4-pgsql \
    php8.4-xml \
    php8.4-zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require "squizlabs/php_codesniffer:^3.10" --no-interaction --no-progress \
    && php -v && composer --version

# ---------------------------------------------------------------------------
# 9. Scripts & environment summary
# ---------------------------------------------------------------------------
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# ---------------------------------------------------------------------------
# 10. Jules and Localharness
# ---------------------------------------------------------------------------
COPY --from=builder /jules /usr/local/bin/jules
COPY --from=builder /go/bin/localharness /usr/local/bin/localharness

WORKDIR /workspace

# ---------------------------------------------------------------------------
# 11. Final configuration
# ---------------------------------------------------------------------------

# Consolidate PATH additions for Go, Poetry, and Composer global bin, plus workspace scripts.
ENV PATH="/opt/scripts:/usr/local/go/bin:/root/.local/bin:/root/.config/composer/vendor/bin:${PATH}" \
    GIT_ASKPASS="/opt/scripts/git-askpass.sh"

# Trust all directories for Git (useful for workspaces and Remote Development)
RUN git config --system --add safe.directory '*' \
    && git config --system user.email "jules-ai-agent@divmora.com" \
    && git config --system user.name "Jules AI Agent"

# systemd requires /run and /sys/fs/cgroup to be available.
VOLUME ["/sys/fs/cgroup"]

# Boot via systemd — Docker and other services start automatically.
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
