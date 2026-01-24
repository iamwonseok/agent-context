# Docker-02-01: Combine RUN commands - FAIL (multiple consecutive RUN)
# Tool: hadolint (DL3059)

FROM ubuntu:24.04

RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y git
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/data
RUN chmod 755 /app
RUN chown -R nobody:nogroup /app

WORKDIR /app

COPY . .

CMD ["./start.sh"]
