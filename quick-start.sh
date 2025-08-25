#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 E2E DevOps Fullstack Application - Quick Start${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if user is logged in to DockerHub by testing a simple pull
echo -e "${YELLOW}🔐 Checking DockerHub login status...${NC}"
if ! docker pull hello-world:latest > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  You are not logged in to DockerHub. Please run 'docker login' first.${NC}"
    echo -e "${YELLOW}   Command: docker login${NC}"
    exit 1
fi
echo -e "${GREEN}✅ DockerHub login verified${NC}"

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo -e "${RED}❌ Minikube is not installed. Please install minikube first.${NC}"
    echo -e "${YELLOW}   Visit: https://minikube.sigs.k8s.io/docs/start/${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    echo -e "${YELLOW}   Visit: https://kubernetes.io/docs/tasks/tools/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites are met!${NC}"
echo ""

# Step 1: Build and Push Docker Images
echo -e "${YELLOW}📦 Step 1: Building and pushing Docker images...${NC}"
./docker-build-push.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed. Please check the errors above.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker images built and pushed successfully!${NC}"
echo ""

# Step 1.5: Generate Kubernetes Manifests
echo -e "${YELLOW}🔧 Step 1.5: Generating Kubernetes manifests...${NC}"
chmod +x generate-k8s-manifests.sh
./generate-k8s-manifests.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Manifest generation failed. Please check the errors above.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Kubernetes manifests generated successfully!${NC}"
echo ""

# Step 2: Start Minikube
echo -e "${YELLOW}🔧 Step 2: Starting Minikube...${NC}"
if ! minikube status | grep -q "Running"; then
    minikube start --cpus=4 --memory=4096 --disk-size=20g
    minikube addons enable ingress
    minikube addons enable metrics-server
else
    echo -e "${GREEN}✅ Minikube is already running${NC}"
fi

echo ""

# Step 3: Deploy to Kubernetes
echo -e "${YELLOW}🚀 Step 3: Deploying to Kubernetes...${NC}"
./deploy.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Kubernetes deployment failed. Please check the errors above.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Application deployed successfully!${NC}"
echo ""

# Get minikube IP and display access information
MINIKUBE_IP=$(minikube ip)
echo -e "${GREEN}📋 Access your application:${NC}"
echo -e "  • Frontend: http://${MINIKUBE_IP}"
echo -e "  • Payment API: http://${MINIKUBE_IP}/api/payment"
echo -e "  • Project API: http://${MINIKUBE_IP}/api/project"
echo -e "  • User API: http://${MINIKUBE_IP}/api/user"
echo ""

echo -e "${GREEN}🔍 Useful commands:${NC}"
echo -e "  • Check status: kubectl get pods -n e2e-devops"
echo -e "  • View logs: kubectl logs -f deployment/payment-service -n e2e-devops"
echo -e "  • Minikube dashboard: minikube dashboard"
echo ""

echo -e "${GREEN}🚀 Your E2E DevOps application is now running on Kubernetes!${NC}"
