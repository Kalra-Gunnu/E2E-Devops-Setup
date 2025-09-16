#!/usr/bin/env bash
set -euo pipefail
AWS_DEFAULT_REGION=${1:-us-west-2}
AWS_ACCOUNT_ID=${2:-}
AWS_ACCESS_KEY_ID=${3:-}
AWS_SECRET_ACCESS_KEY=${4:-}
TAG=${5:-latest}
ECR_REGISTRY=${6:-}
DOCKER_USERNAME=${7}
DOCKER_REPO_NAME=${8:-e2e-devops}

if [ -z "$AWS_DEFAULT_REGION" || -z "$TAG" || -z "$ECR_REGISTRY" || -z "$DOCKER_USERNAME" || -z "$DOCKER_REPO_NAME" ]; then
  echo "Usage: $0 <aws_default_region> <tag> <ecr_registry> <docker_username> <docker_repo_name>"
  exit 2
fi

services=("g5_slabai_payment" "g5_slabai_project" "g5_slabai_user" "g5_slabai_frontend")

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$ECR_REGISTRY"
for s in "${services[@]}"; do
  local="$DOCKER_USERNAME/$DOCKER_REPO_NAME-$s:$TAG"
  remote="$ECR_REGISTRY/$DOCKER_REPO_NAME-$s:$TAG"
  docker tag "$local" "$remote"
  docker push "$remote"
done
