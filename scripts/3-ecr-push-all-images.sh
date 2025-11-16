#!/usr/bin/env bash
set -euo pipefail
AWS_DEFAULT_REGION=${1:-us-west-2}
IMAGE_TAG=${2:-latest}
ECR_REGISTRY=${3:-}
DOCKER_USERNAME=${4:-}
DOCKER_REPO_NAME=${5:-g5-slabai}
AWS_PROFILE=${6:-herovired}

services=("payment-service" "project-service" "user-service" "frontend")

aws ecr get-login-password --region $AWS_DEFAULT_REGION --profile $AWS_PROFILE | docker login --username AWS --password-stdin $ECR_REGISTRY

for s in "${services[@]}"; do
  local="$DOCKER_USERNAME/$DOCKER_REPO_NAME-$s:$IMAGE_TAG"
  remote="$ECR_REGISTRY/$DOCKER_REPO_NAME-$s:$IMAGE_TAG"
  echo "Tagging $local as $remote"
  docker tag "$local" "$remote"
  docker push "$remote"
done
