#!/usr/bin/env bash
set -euo pipefail
TAG=${1:-latest}
ECR_REGISTRY=${2:-}
if [ -z "$ECR_REGISTRY" ]; then
  echo "Usage: $0 <tag> <ecr_registry>"
  exit 2
fi
services=("payment-service" "project-service" "user-service" "frontend")
aws ecr get-login-password --region ${AWS_DEFAULT_REGION:-ap-south-1} | docker login --username AWS --password-stdin "$ECR_REGISTRY"
for s in "${services[@]}"; do
  local="$s:$TAG"
  remote="$ECR_REGISTRY/$s:$TAG"
  docker tag "$local" "$remote"
  docker push "$remote"
done
