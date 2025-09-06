#!/usr/bin/env bash
set -euo pipefail
TAG=${1:-latest}
DOCKER_USERNAME=${2:-prag1402}
DOCKER_REPO_NAME=${3:-e2e-devops}

services=("payment-service" "project-service" "user-service" "frontend")
for s in "${services[@]}"; do
  IMAGE="$DOCKER_USERNAME/$DOCKER_REPO_NAME-$s:$TAG"
  echo "Scanning $IMAGE"
  trivy image --severity CRITICAL,HIGH "$IMAGE" 
  # --exit-code 1 --severity CRITICAL,HIGH "$IMAGE" || { echo "Scan failed for $IMAGE"; exit 1; }
done
echo "All images scanned"
