#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TAG=${1:-latest}
DOCKER_USERNAME=${2:-}
DOCKER_REPO_NAME=${3:-g5-slabai}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load configuration from config.env file if available
if [ -f "${ROOT_DIR}/config.env" ]; then
    set -a  # Auto-export all variables
    source "${ROOT_DIR}/config.env"
    set +a  # Turn off auto-export
    echo -e "${GREEN}✅ Configuration loaded from ${ROOT_DIR}/config.env${NC}"
fi

echo -e "${GREEN}🚀 Starting Docker build and push process...${NC}"

# Function to build and push a service
build_and_push_service() {
    local service_name=$1
    local service_path=$2
    local port=$3
    
    echo -e "${YELLOW}📦 Building ${service_name}...${NC}"
    
    # Build the Docker image for linux/amd64 platform (EKS nodes use x86_64)
    if [ "$service_name" == "frontend" ]; then
        docker build --platform linux/amd64 -t ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-${service_name}:${TAG} \
            --build-arg NODE_ENV=${NODE_ENV:-production} \
            --build-arg COMPANY_NAME="${COMPANY_NAME:-Dey Education}" \
            --build-arg CURRENCY=${CURRENCY:-INR} \
            ${service_path}
    else
        docker build --platform linux/amd64 -t ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-${service_name}:${TAG} ${service_path}
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${service_name} built successfully${NC}"
        
        echo -e "${YELLOW}🚀 Pushing ${service_name} to DockerHub...${NC}"
        
        # Push to DockerHub
        docker push ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-${service_name}:${TAG}
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ ${service_name} pushed successfully to DockerHub${NC}"
        else
            echo -e "${RED}❌ Failed to push ${service_name} to DockerHub${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed to build ${service_name}${NC}"
        exit 1
    fi
    
    echo ""
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if user is logged in to DockerHub by testing a simple pull
echo -e "${YELLOW}🔐 Checking DockerHub login status...${NC}"
if ! docker pull hello-world:latest > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  You are not logged in to DockerHub. Please run 'docker login' first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ DockerHub login verified${NC}"

# Build and push each service
build_and_push_service "payment-service" "${ROOT_DIR}/backend/paymentService" 3000
build_and_push_service "project-service" "${ROOT_DIR}/backend/projectService" 3001
build_and_push_service "user-service" "${ROOT_DIR}/backend/userService" 3002
build_and_push_service "frontend" "${ROOT_DIR}/frontend" 80

echo -e "${GREEN}🎉 All services have been built and pushed successfully!${NC}"
echo ""
echo -e "${GREEN}📋 Image URLs:${NC}"
echo -e "  • ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-payment-service:${TAG}"
echo -e "  • ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-project-service:${TAG}"
echo -e "  • ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-user-service:${TAG}"
echo -e "  • ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-frontend:${TAG}"
echo ""
echo -e "${GREEN}🚀 Ready to deploy on Kubernetes!${NC}"