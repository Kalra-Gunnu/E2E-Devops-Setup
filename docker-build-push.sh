#!/bin/bash

# Load configuration from config.env file
if [ -f "config.env" ]; then
    source config.env
    echo -e "${GREEN}✅ Configuration loaded from config.env${NC}"
else
    echo -e "${YELLOW}⚠️  config.env not found, using default values${NC}"
    # Default values
    DOCKER_USERNAME="<your docker hub user>"
    DOCKER_REPO_NAME="e2e-devops"
fi

# Use DOCKER_REPO_NAME from config, fallback to REPO_NAME for backward compatibility
REPO_NAME=${DOCKER_REPO_NAME:-"e2e-devops"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Docker build and push process...${NC}"

# Function to build and push a service
build_and_push_service() {
    local service_name=$1
    local service_path=$2
    local port=$3
    
    echo -e "${YELLOW}📦 Building ${service_name}...${NC}"
    
    # Build the Docker image
    docker build -t ${DOCKER_USERNAME}/${REPO_NAME}-${service_name}:latest ${service_path}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${service_name} built successfully${NC}"
        
        echo -e "${YELLOW}🚀 Pushing ${service_name} to DockerHub...${NC}"
        
        # Push to DockerHub
        docker push ${DOCKER_USERNAME}/${REPO_NAME}-${service_name}:latest
        
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
build_and_push_service "payment-service" "./backend/paymentService" 3000
build_and_push_service "project-service" "./backend/projectService" 3001
build_and_push_service "user-service" "./backend/userService" 3002

echo -e "${GREEN}🎉 All services have been built and pushed successfully!${NC}"
echo ""
echo -e "${GREEN}📋 Image URLs:${NC}"
echo -e "  • ${DOCKER_USERNAME}/${REPO_NAME}/payment-service:latest"
echo -e "  • ${DOCKER_USERNAME}/${REPO_NAME}/project-service:latest"
echo -e "  • ${DOCKER_USERNAME}/${REPO_NAME}/user-service:latest"
echo ""
echo -e "${GREEN}🚀 Ready to deploy on Kubernetes!${NC}"
