#!/usr/bin/env bash
set -euo pipefail
AWS_DEFAULT_REGION=${1:-us-west-2}
TAG=${2:-latest}
ECR_REGISTRY=${3:-}
DOCKER_USERNAME=${4:-prag1402}
DOCKER_REPO_NAME=${5:-e2e-devops}

if [ -z "$AWS_DEFAULT_REGION" || -z "$TAG" || -z "$ECR_REGISTRY" || -z "$DOCKER_USERNAME" || -z "$DOCKER_REPO_NAME" ]; then
  echo "Usage: $0 <aws_default_region> <tag> <ecr_registry> <docker_username> <docker_repo_name>"
  exit 2
fi

services=("payment-service" "project-service" "user-service" "frontend")

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$ECR_REGISTRY"
for s in "${services[@]}"; do
  local="$DOCKER_USERNAME/$DOCKER_REPO_NAME-$s:$TAG"
  remote="$ECR_REGISTRY/$DOCKER_REPO_NAME-$s:$TAG"
  docker tag "$local" "$remote"
  docker push "$remote"
done
