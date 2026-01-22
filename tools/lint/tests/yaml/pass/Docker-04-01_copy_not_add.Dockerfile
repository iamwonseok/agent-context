# Docker-04-01: Use COPY instead of ADD - PASS
# Tool: hadolint (DL3010)

FROM ubuntu:24.04

WORKDIR /app

# Use COPY for local files
COPY package.json .
COPY src/ ./src/
COPY config/ ./config/

# ADD is only appropriate for:
# - Extracting tar archives
# - Downloading from URLs (though curl/wget is preferred)

CMD ["./start.sh"]
