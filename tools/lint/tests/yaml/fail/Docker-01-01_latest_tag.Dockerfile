# Docker-01-01: Use specific image tags - FAIL (uses :latest)
# Tool: hadolint (DL3006, DL3007)

FROM ubuntu:latest

LABEL maintainer="team@example.com"

RUN apt-get update && \
    apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

CMD ["./start.sh"]
