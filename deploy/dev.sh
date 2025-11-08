#!/usr/bin/env bash
set -euo pipefail

# Resolve docker path robustly for Jenkins/macOS
DOCKER_BIN="${DOCKER:-/usr/local/bin/docker}"

if ! command -v "$DOCKER_BIN" >/dev/null 2>&1; then
  # Fallbacks if DOCKER not set or /usr/local/bin/docker doesn’t exist
  if command -v /usr/local/bin/docker >/dev/null 2>&1; then
    DOCKER_BIN="/usr/local/bin/docker"
  elif command -v /Applications/Docker.app/Contents/Resources/bin/docker >/dev/null 2>&1; then
    DOCKER_BIN="/Applications/Docker.app/Contents/Resources/bin/docker"
  elif command -v docker >/dev/null 2>&1; then
    DOCKER_BIN="$(command -v docker)"
  else
    echo "❌ docker not found in PATH; set DOCKER env var or ensure /usr/local/bin/docker exists"
    exit 127
  fi
fi

IMAGE="${1:?Usage: dev.sh <image:tag>}"

# Stop old dev container if present
"$DOCKER_BIN" rm -f moji-hello-dev 2>/dev/null || true

# Run updated image (publish 8000 locally so you can test in browser)
"$DOCKER_BIN" run -d --name moji-hello-dev -p 8000:8000 "$IMAGE"

# Quick health check against the running container
"$DOCKER_BIN" run --rm --network container:moji-hello-dev curlimages/curl:8.11.0 -s http://localhost:8000/healthz | grep '"ok":true'

echo "✅ Deployed $IMAGE to container moji-hello-dev"
