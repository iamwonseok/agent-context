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
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    python3 \
    python3-pip \
    pandoc \
    wget \
    && rm -rf /var/lib/apt/lists/*

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
ARG GLAB_VERSION=1.36.0
RUN wget -qO- "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_Linux_x86_64.tar.gz" \
    | tar xz -C /usr/local/bin --strip-components=1 bin/glab \
    && chmod +x /usr/local/bin/glab

# ============================================================
# Install pre-commit (optional, for best-effort checks)
# ============================================================
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
