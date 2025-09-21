#!/usr/bin/env bash
set -euo pipefail
AWS_DEFAULT_REGION=${1:-us-west-2}
TAG=${2:-latest}
ECR_REGISTRY=${3:-}
DOCKER_USERNAME=${4}
DOCKER_REPO_NAME=${5:-e2e-devops}

if [[ -z "$AWS_DEFAULT_REGION" || -z "$TAG" || -z "$ECR_REGISTRY" || -z "$DOCKER_USERNAME" || -z "$DOCKER_REPO_NAME" ]]; then
  echo "Usage: $0 <aws_default_region> <tag> <ecr_registry> <docker_username> <docker_repo_name>"
  exit 2
fi

services=("g5-slabai-payment" "g5-slabai-project" "g5-slabai-user" "g5-slabai-frontend")
local_names=("g5-slabai-payment-service" "g5-slabai-project-service" "g5-slabai-user-service" "g5-slabai-frontend")

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$ECR_REGISTRY"
for i in "${!services[@]}"; do
  s="${services[$i]}"
  local_name="${local_names[$i]}"
  local="$DOCKER_USERNAME/$local_name:$TAG"
  remote="$ECR_REGISTRY/$s:$TAG"
  docker tag "$local" "$remote"
  docker push "$remote"
done
