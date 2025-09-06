#!/usr/bin/env bash
set -euo pipefail
TAG=${1:-latest}
services=("payment-service" "project-service" "user-service" "frontend")
for s in "${services[@]}"; do
  IMAGE="$s:$TAG"
  echo "Scanning $IMAGE"
  trivy image --exit-code 1 --severity CRITICAL,HIGH "$IMAGE" || { echo "Scan failed for $IMAGE"; exit 1; }
done
echo "All images scanned"
