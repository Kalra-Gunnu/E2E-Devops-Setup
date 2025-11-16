#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"

# Load configuration from config.env file
if [ -f "${ROOT_DIR}/config.env" ]; then
    set -a  # Auto-export all variables
    source "${ROOT_DIR}/config.env"
    set +a  # Turn off auto-export
    echo -e "${GREEN}✅ Configuration loaded and exported from ${ROOT_DIR}/config.env${NC}"
else
    echo -e "${YELLOW}⚠️  config.env not found at ${ROOT_DIR}/config.env, using default values${NC}"
    # Default values
    DOCKER_USERNAME="user-name"
    DOCKER_REPO_NAME="g5-slabai"
    export DOCKER_USERNAME DOCKER_REPO_NAME
fi

echo -e "${BLUE}🚀 E2E DevOps Fullstack Application - Quick Start${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Step 1: Build and Push Docker Images
echo -e "${YELLOW}📦 Step 1: Building and pushing Docker images...${NC}"
sh ./scripts/1-docker-build-push.sh ${IMAGE_TAG} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed. Please check the errors above.${NC}"
    exit 1
fi

# Step 2: Scan Images with Trivy
echo -e "${YELLOW}🚀 Step 2: Scanning images with Trivy...${NC}"
sh ./scripts/2-trivy-scan-all.sh ${IMAGE_TAG} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}

# if [ $? -ne 0 ]; then
#     echo -e "${RED}❌ Trivy scan failed. Please check the errors above.${NC}"
#     exit 1
# fi

# Step 3: Push to ECR
echo -e "${YELLOW}🚀 Step 3: Pushing to ECR...${NC}"
sh ./scripts/3-ecr-push-all-images.sh ${AWS_REGION} ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}

# if [ $? -ne 0 ]; then
#     echo -e "${RED}❌ ECR push failed. Please check the errors above.${NC}"
#     exit 1
# fi

echo -e "${GREEN}✅ Docker images built and pushed successfully!${NC}"
echo ""

# Step 4: Deploy to EKS Cluster
echo -e "${YELLOW}🚀 Step 3: Deploying to EKS...${NC}"
sh ./scripts/4-deploy-eks-cluster.sh ${IMAGE_TAG} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Kubernetes deployment failed. Please check the errors above.${NC}"
    exit 1
fi
