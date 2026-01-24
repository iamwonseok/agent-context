# Docker-02-01: Combine RUN commands - PASS
# Tool: hadolint (DL3059)

FROM ubuntu:24.04

# Single RUN with combined commands
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Application setup in single RUN
RUN mkdir -p /app/data && \
    chmod 755 /app && \
    chown -R nobody:nogroup /app

WORKDIR /app

COPY . .

CMD ["./start.sh"]
