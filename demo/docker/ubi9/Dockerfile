# Agent-Context Demo - UBI9 Image (Red Hat Universal Base Image 9)
# For testing installation on Red Hat Enterprise Linux based systems
#
# Build:
#   docker build -t agent-context-demo-ubi9 -f demo/docker/ubi9/Dockerfile demo/docker/ubi9
#
# Run:
#   docker run --rm -it -v ~/.secrets:/root/.secrets:ro agent-context-demo-ubi9

FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL maintainer="Agent Context Team"
LABEL description="Agent-Context demo installation environment (UBI9/RHEL9)"

# ============================================================
# Install base dependencies
# ============================================================
RUN dnf install -y --nodocs \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    python3 \
    python3-pip \
    wget \
    tar \
    gzip \
    && dnf clean all

# ============================================================
# Install pandoc (manual install for RHEL)
# ============================================================
ARG PANDOC_VERSION=3.1.11
RUN wget -qO- "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz" \
    | tar xz -C /usr/local --strip-components=1

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

# Copy entrypoint (shared with ubuntu)
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
