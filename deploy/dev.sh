#!/usr/bin/env bash
set -euo pipefail

# Resolve docker path robustly for Jenkins/macOS
DOCKER_BIN="${DOCKER:-/usr/local/bin/docker}"
if ! command -v "$DOCKER_BIN" >/dev/null 2>&1; then
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

# Try to publish on 8000..8010, pick the first free one
PORT_CHOSEN=""
for PORT in $(seq 8000 8010); do
  set +e
  CID=$("$DOCKER_BIN" run -d --name moji-hello-dev -p "${PORT}:8000" "$IMAGE" 2>&1)
  STATUS=$?
  set -e
  if [ $STATUS -eq 0 ]; then
    PORT_CHOSEN="$PORT"
    echo "✅ Started moji-hello-dev on localhost:${PORT_CHOSEN}"
    break
  else
    echo "⚠️  Port ${PORT} busy, trying next... (${CID})"
    # Ensure no half-created container lingers
    "$DOCKER_BIN" rm -f moji-hello-dev >/dev/null 2>&1 || true
  fi
done

if [ -z "${PORT_CHOSEN}" ]; then
  echo "❌ Could not bind any port in 8000..8010. Free a port or adjust the range."
  exit 125
fi

# Health check against the running container via container network
"$DOCKER_BIN" run --rm --network container:moji-hello-dev curlimages/curl:8.11.0 -s http://localhost:8000/healthz | grep '"ok":true'

echo "✅ Deployed $IMAGE to container moji-hello-dev (http://localhost:${PORT_CHOSEN})"
