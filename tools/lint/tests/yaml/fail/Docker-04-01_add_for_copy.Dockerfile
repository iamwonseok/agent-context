# Docker-04-01: Use COPY instead of ADD - FAIL (uses ADD for simple copy)
# Tool: hadolint (DL3010)

FROM ubuntu:24.04

WORKDIR /app

# Using ADD when COPY should be used
ADD package.json .
ADD src/ ./src/
ADD config/ ./config/

CMD ["./start.sh"]
