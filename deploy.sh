#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Kubernetes deployment...${NC}"

# Check if kind cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${YELLOW}⚠️  Kind cluster is not running. Please start Docker Desktop with Kubernetes enabled.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Kind cluster is running${NC}"

# Check if ingress controller is available
echo -e "${YELLOW}🔧 Checking ingress controller...${NC}"

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

# Get cluster IP (for kind, we'll use localhost)
CLUSTER_IP="localhost"

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${GREEN}📋 Service URLs:${NC}"
echo -e "  • Frontend: http://${CLUSTER_IP}"
echo -e "  • Payment Service: http://${CLUSTER_IP}/api/payment"
echo -e "  • Project Service: http://${CLUSTER_IP}/api/project"
echo -e "  • User Service: http://${CLUSTER_IP}/api/user"
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
