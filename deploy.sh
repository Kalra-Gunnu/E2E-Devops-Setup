#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Kubernetes deployment...${NC}"

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo -e "${YELLOW}⚠️  Minikube is not running. Starting minikube...${NC}"
    minikube start --cpus=4 --memory=4096 --disk-size=20g
fi

# Enable addons
echo -e "${YELLOW}🔧 Enabling required addons...${NC}"
minikube addons enable ingress
minikube addons enable metrics-server

# Wait for ingress controller to be ready
echo -e "${YELLOW}⏳ Waiting for ingress controller to be ready...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Create namespace
echo -e "${YELLOW}📦 Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap and Secrets
echo -e "${YELLOW}🔐 Applying ConfigMap and Secrets...${NC}"
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# Deploy databases
echo -e "${YELLOW}🗄️  Deploying databases...${NC}"
kubectl apply -f k8s/mongodb.yaml
kubectl apply -f k8s/redis.yaml

# Wait for databases to be ready
echo -e "${YELLOW}⏳ Waiting for databases to be ready...${NC}"
kubectl wait --namespace e2e-devops \
  --for=condition=ready pod \
  --selector=app=mongodb \
  --timeout=120s

kubectl wait --namespace e2e-devops \
  --for=condition=ready pod \
  --selector=app=redis \
  --timeout=120s

# Deploy backend services
echo -e "${YELLOW}🔧 Deploying backend services...${NC}"
kubectl apply -f k8s/payment-service.yaml
kubectl apply -f k8s/project-service.yaml
kubectl apply -f k8s/user-service.yaml

# Deploy frontend
echo -e "${YELLOW}🌐 Deploying frontend...${NC}"
kubectl apply -f k8s/frontend-service.yaml

# Deploy ingress
echo -e "${YELLOW}🚪 Deploying ingress...${NC}"
kubectl apply -f k8s/ingress.yaml

# Wait for all pods to be ready
echo -e "${YELLOW}⏳ Waiting for all services to be ready...${NC}"
kubectl wait --namespace e2e-devops \
  --for=condition=ready pod \
  --selector=app=payment-service \
  --timeout=120s

kubectl wait --namespace e2e-devops \
  --for=condition=ready pod \
  --selector=app=project-service \
  --timeout=120s

kubectl wait --namespace e2e-devops \
  --for=condition=ready pod \
  --selector=app=user-service \
  --timeout=120s

kubectl wait --namespace e2e-devops \
  --for=condition=ready pod \
  --selector=app=frontend \
  --timeout=120s

# Get minikube IP
MINIKUBE_IP=$(minikube ip)

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${GREEN}📋 Service URLs:${NC}"
echo -e "  • Frontend: http://${MINIKUBE_IP}"
echo -e "  • Payment Service: http://${MINIKUBE_IP}/api/payment"
echo -e "  • Project Service: http://${MINIKUBE_IP}/api/project"
echo -e "  • User Service: http://${MINIKUBE_IP}/api/user"
echo ""
echo -e "${GREEN}🔍 Check deployment status:${NC}"
echo -e "  kubectl get pods -n e2e-devops"
echo -e "  kubectl get services -n e2e-devops"
echo -e "  kubectl get ingress -n e2e-devops"
echo ""
echo -e "${GREEN}📊 Monitor logs:${NC}"
echo -e "  kubectl logs -f deployment/payment-service -n e2e-devops"
echo -e "  kubectl logs -f deployment/project-service -n e2e-devops"
echo -e "  kubectl logs -f deployment/user-service -n e2e-devops"
