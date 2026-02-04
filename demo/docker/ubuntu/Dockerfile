# Agent-Context Demo - Ubuntu Image
# For testing installation on Ubuntu-based systems
#
# Build:
#   docker build -t agent-context-demo-ubuntu -f demo/docker/ubuntu/Dockerfile demo/docker/ubuntu
#
# Run:
#   docker run --rm -it -v ~/.secrets:/root/.secrets:ro agent-context-demo-ubuntu

FROM ubuntu:22.04

LABEL maintainer="Agent Context Team"
LABEL description="Agent-Context demo installation environment (Ubuntu)"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ============================================================
# Install base dependencies
# ============================================================
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    python3 \
    python3-pip \
    pandoc \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Use bash with pipefail for piped RUN commands
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ============================================================
# Install yq (mikefarah/yq)
# ============================================================
ARG YQ_VERSION=v4.40.5
RUN wget -qO /usr/local/bin/yq \
    "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq

# ============================================================
# Install glab (GitLab CLI)
# ============================================================
ARG GLAB_VERSION=1.81.0
RUN arch="$(uname -m)" && \
    case "${arch}" in \
        x86_64|amd64) asset_arch="amd64" ;; \
        aarch64|arm64) asset_arch="arm64" ;; \
        *) echo "Unsupported arch: ${arch}" && exit 1 ;; \
    esac && \
    wget -qO- "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_${asset_arch}.tar.gz" \
        | tar xz -C /usr/local/bin --strip-components=1 bin/glab && \
    chmod +x /usr/local/bin/glab

# ============================================================
# Install pre-commit (optional, for best-effort checks)
# ============================================================
# hadolint ignore=DL3013
RUN pip3 install --no-cache-dir pre-commit

# ============================================================
# Setup working environment
# ============================================================
WORKDIR /workspace

# Create secrets directory (will be mounted at runtime)
RUN mkdir -p /root/.secrets && chmod 700 /root/.secrets

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ============================================================
# Environment variables
# ============================================================
# These can be overridden at runtime
ENV PROFILE=full
ENV SKIP_E2E=false
ENV FORCE=false

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
