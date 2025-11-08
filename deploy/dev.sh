#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:?Usage: dev.sh <image:tag>}"

docker rm -f moji-hello-dev 2>/dev/null || true
docker run -d --name moji-hello-dev -p 8000:8000 "$IMAGE"

docker run --rm --network container:moji-hello-dev curlimages/curl:8.11.0 -s http://localhost:8000/healthz | grep '"ok":true'
echo "✅ Deployed $IMAGE to container moji-hello-dev"
