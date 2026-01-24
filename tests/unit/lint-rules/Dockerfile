# Coding Convention Test Environment
# Contains all linting and formatting tools for C, Bash, Python, Make, YAML

FROM ubuntu:24.04

LABEL maintainer="SoC Team"
LABEL description="Coding convention testing environment with linting tools"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install base packages and repositories
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    gnupg \
    software-properties-common \
    git \
    file \
    make \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install LLVM/Clang tools (clang-format, clang-tidy)
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-19 main" > /etc/apt/sources.list.d/llvm.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    clang-format-19 \
    clang-tidy-19 \
    && ln -s /usr/bin/clang-format-19 /usr/bin/clang-format \
    && ln -s /usr/bin/clang-tidy-19 /usr/bin/clang-tidy \
    && rm -rf /var/lib/apt/lists/*

# Install cppcheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    cppcheck \
    && rm -rf /var/lib/apt/lists/*

# Install ShellCheck
RUN apt-get update && apt-get install -y --no-install-recommends \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install shfmt
RUN curl -sS https://webi.sh/shfmt | sh \
    && mv ~/.local/bin/shfmt /usr/local/bin/

# Install Python and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Install Python linting tools
RUN pip3 install --no-cache-dir --break-system-packages \
    black==24.10.0 \
    flake8==7.1.1 \
    isort==5.13.2 \
    mypy==1.13.0 \
    yamllint==1.35.1

# Install hadolint for Dockerfile linting
RUN curl -sL https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint \
    && chmod +x /usr/local/bin/hadolint

# Install checkmake for Makefile linting
RUN apt-get update && apt-get install -y --no-install-recommends \
    golang-go \
    && go install github.com/checkmake/checkmake/cmd/checkmake@latest \
    && mv /root/go/bin/checkmake /usr/local/bin/ \
    && apt-get remove -y golang-go \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /root/go

# Install pre-commit
RUN pip3 install --no-cache-dir --break-system-packages pre-commit==4.0.1

# Set working directory
WORKDIR /work

# Verify installations
RUN echo "=== Tool Versions ===" \
    && clang-format --version \
    && clang-tidy --version \
    && cppcheck --version \
    && shellcheck --version \
    && shfmt --version \
    && black --version \
    && flake8 --version \
    && isort --version \
    && mypy --version \
    && yamllint --version \
    && hadolint --version \
    && checkmake --version \
    && pre-commit --version

# Default command
CMD ["/bin/bash"]
