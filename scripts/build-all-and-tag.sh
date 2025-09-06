#!/usr/bin/env bash
set -euo pipefail
TAG=${1:-latest}
services=("payment-service" "project-service" "user-service" "frontend")
for s in "${services[@]}"; do
  echo "Building $s"
  docker build -t "$s:$TAG" "./services/$s"
done
