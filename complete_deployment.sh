#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load configuration from config.env file
if [ -f "config.env" ]; then
    source config.env
    echo -e "${GREEN}✅ Configuration loaded from config.env${NC}"
else
    echo -e "${YELLOW}⚠️  config.env not found, using default values${NC}"
    # Default values
    DOCKER_USERNAME="prag1402"
    DOCKER_REPO_NAME="e2e-devops"
fi

ECR_REGISTRY=${DOCKER_USERNAME}

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
# echo -e "${YELLOW}🚀 Step 3: Pushing to ECR...${NC}"
# sh ./scripts/3-ecr-push-all-images.sh ${AWS_REGION} ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}

# if [ $? -ne 0 ]; then
#     echo -e "${RED}❌ ECR push failed. Please check the errors above.${NC}"
#     exit 1
# fi

echo -e "${GREEN}✅ Docker images built and pushed successfully!${NC}"
echo ""

# Step 2: Deploy to Kubernetes
echo -e "${YELLOW}🚀 Step 3: Deploying to Kubernetes...${NC}"
sh ./scripts/4-deploy-kube-cluster.sh ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_REPO_NAME}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Kubernetes deployment failed. Please check the errors above.${NC}"
    exit 1
fi
