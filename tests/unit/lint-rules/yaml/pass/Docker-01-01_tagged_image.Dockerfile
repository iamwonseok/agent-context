# Docker-01-01: Use specific image tags - PASS
# Tool: hadolint (DL3006, DL3007)

FROM ubuntu:24.04

LABEL maintainer="team@example.com"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl=8.5.0-2ubuntu10.1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

CMD ["./start.sh"]
