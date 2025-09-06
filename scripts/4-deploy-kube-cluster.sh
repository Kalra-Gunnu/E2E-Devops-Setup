#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ROOT_DIR="."
K8_DIR="${ROOT_DIR}/k8s"
TAG=${1:-latest}
DOCKER_USERNAME=${2:-prag1402}
DOCKER_REPO_NAME=${3:-e2e-devops}

if [ -z "$DOCKER_USERNAME" || -z "$DOCKER_REPO_NAME" ]; then
    echo -e "${RED}❌ DOCKER_USERNAME or DOCKER_REPO_NAME is not set. Please set them in config.env.${NC}"
    exit 1
fi

## Check if kind cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kind cluster is not running. Please enable Kubernetes in Docker Desktop.${NC}"
    echo -e "${YELLOW}   Go to Docker Desktop > Settings > Kubernetes > Enable Kubernetes${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Kind cluster is running${NC}"

## Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    echo -e "${YELLOW}   Visit: https://kubernetes.io/docs/tasks/tools/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All Deployment Prerequisites are met!${NC}"
echo ""

echo -e "${BLUE}🚀 Starting Kubernetes deployment...${NC}"

# Install NGINX Ingress Controller for Docker Desktop Kubernetes
echo -e "${YELLOW} Installing NGINX Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
echo -e "${YELLOW}⏳ Waiting for ingress controller to be ready...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Install envsubst
echo -e "${YELLOW}🔧 Installing envsubst...${NC}"
sudo apt-get install -y gettext-base

# Export variables for envsubst
export DOCKER_USERNAME
export TAG
export DOCKER_REPO_NAME

# Create namespace
echo -e "${YELLOW}📦 Creating namespace...${NC}"
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/namespace.yaml | kubectl apply -f -

# Apply ConfigMap and Secrets
echo -e "${YELLOW}🔐 Applying ConfigMap and Secrets...${NC}"
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/configmap.yaml | kubectl apply -f -
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/secret.yaml | kubectl apply -f -

# Deploy databases
echo -e "${YELLOW}🗄️  Deploying databases...${NC}"
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/mongodb.yaml | kubectl apply -f -
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/redis.yaml | kubectl apply -f -

# Wait for databases to be ready
echo -e "${YELLOW}⏳ Waiting for databases to be ready...${NC}"
kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=mongodb \
  --timeout=120s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=redis \
  --timeout=120s

# Deploy backend services
echo -e "${YELLOW}🔧 Deploying backend services...${NC}"
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/payment-service.yaml | kubectl apply -f -
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/project-service.yaml | kubectl apply -f -
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/user-service.yaml | kubectl apply -f -

# Deploy frontend
echo -e "${YELLOW}🌐 Deploying frontend...${NC}"
envsubst '$DOCKER_USERNAME $TAG $DOCKER_REPO_NAME' < ${K8_DIR}/frontend-service.yaml | kubectl apply -f -

# Deploy ingress
echo -e "${YELLOW}🚪 Deploying ingress...${NC}"
kubectl apply -f ${K8_DIR}/ingress.yaml

# Wait for all pods to be ready
echo -e "${YELLOW}⏳ Waiting for all services to be ready...${NC}"
kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=payment-service \
  --timeout=120s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=project-service \
  --timeout=120s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=user-service \
  --timeout=120s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=frontend \
  --timeout=120s

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${GREEN}📋 Service URLs:${NC}"
echo -e "  • Frontend: http://${CLUSTER_IP}"
echo -e "  • Payment Service: http://${CLUSTER_IP}/api/payment"
echo -e "  • Project Service: http://${CLUSTER_IP}/api/project"
echo -e "  • User Service: http://${CLUSTER_IP}/api/user"
echo ""
echo -e "${GREEN}🔍 Check deployment status:${NC}"
echo -e "  kubectl get pods -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl get services -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl get ingress -n ${DOCKER_REPO_NAME}"
echo ""
echo -e "${GREEN}📊 Monitor logs:${NC}"
echo -e "  kubectl logs -f deployment/payment-service -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl logs -f deployment/project-service -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl logs -f deployment/user-service -n ${DOCKER_REPO_NAME}"
echo ""
echo -e "${YELLOW}🚀 Access Kubernetes dashboard:${NC}"
echo -e "  kubectl proxy (then visit http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/)"
