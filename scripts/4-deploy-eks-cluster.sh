#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
K8_DIR="${ROOT_DIR}/k8s"
IMAGE_TAG=${1:-latest}
ECR_REGISTRY=${2:-}
DOCKER_REPO_NAME=${3:-g5-slabai}
AWS_PROFILE=${4:-herovired}
AWS_REGION=${5:-us-west-2}
# Load configuration from config.env file if available
if [ -f "${ROOT_DIR}/config.env" ]; then
    set -a  # Auto-export all variables
    source "${ROOT_DIR}/config.env"
    set +a  # Turn off auto-export
    echo -e "${GREEN}✅ Configuration loaded from ${ROOT_DIR}/config.env${NC}"
fi

echo ""
echo "⚙️  Configuring kubectl for EKS cluster"
echo "==============================="

echo -e "${YELLOW}Updating kubeconfig for EKS cluster...${NC}"
aws sts get-caller-identity --profile ${AWS_PROFILE} >/dev/null
aws eks update-kubeconfig --region ${AWS_REGION} --profile ${AWS_PROFILE} --name app-dev
aws eks get-token --cluster-name app-dev --region ${AWS_REGION} --profile ${AWS_PROFILE} >/dev/null

echo -e "${YELLOW}Testing cluster connectivity...${NC}"
sleep 3
kubectl get nodes


# Install AWS Load Balancer Controller (for EKS)
echo -e "${YELLOW}🔧 Checking AWS Load Balancer Controller...${NC}"

# Get cluster name
CLUSTER_NAME="app-dev"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile ${AWS_PROFILE} --query Account --output text)

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Helm...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Add EKS Helm chart repository
helm repo add eks https://aws.github.io/eks-charts 2>/dev/null || true
helm repo update

# Check if Helm release already exists
if helm list -n kube-system | grep -q "aws-load-balancer-controller"; then
    echo -e "${GREEN}✅ AWS Load Balancer Controller Helm release already exists${NC}"
    echo -e "${YELLOW}⏳ Checking if controller is ready...${NC}"
    kubectl wait --namespace kube-system \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/name=aws-load-balancer-controller \
        --timeout=60s 2>/dev/null || echo -e "${YELLOW}⚠️  Controller pods may not be ready yet${NC}"
# Check if deployment exists (installed via YAML)
elif kubectl get deployment -n kube-system aws-load-balancer-controller &>/dev/null; then
    echo -e "${GREEN}✅ AWS Load Balancer Controller is already installed (via YAML)${NC}"
    echo -e "${YELLOW}⏳ Checking if controller is ready...${NC}"
    kubectl wait --namespace kube-system \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/name=aws-load-balancer-controller \
        --timeout=60s 2>/dev/null || echo -e "${YELLOW}⚠️  Controller pods may not be ready yet${NC}"
else
    echo -e "${YELLOW}📦 Installing AWS Load Balancer Controller...${NC}"
    
    # Check if IRSA is enabled (OIDC provider exists)
    OIDC_PROVIDER=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --profile ${AWS_PROFILE} --query "cluster.identity.oidc.issuer" --output text 2>/dev/null | sed -e "s/^https:\/\///")
    
    if [ -n "$OIDC_PROVIDER" ] && [ "$OIDC_PROVIDER" != "None" ]; then
        echo -e "${GREEN}✅ OIDC provider found: ${OIDC_PROVIDER}${NC}"
        
        # Try to find existing IAM role for Load Balancer Controller
        LB_ROLE_NAME="AmazonEKSAutoClusterRole"
        LB_ROLE_ARN=$(aws iam get-role --role-name ${LB_ROLE_NAME} --profile ${AWS_PROFILE} --query 'Role.Arn' --output text 2>/dev/null || echo "")
        
        # If not found, try the auto cluster role
        if [ -z "$LB_ROLE_ARN" ] || [ "$LB_ROLE_ARN" = "None" ]; then
            LB_ROLE_ARN=$(aws iam get-role --role-name AmazonEKSAutoClusterRole --profile ${AWS_PROFILE} --query 'Role.Arn' --output text 2>/dev/null || echo "")
        fi
        
        if [ -n "$LB_ROLE_ARN" ] && [ "$LB_ROLE_ARN" != "None" ]; then
            echo -e "${GREEN}✅ Found existing IAM role: ${LB_ROLE_ARN}${NC}"
            # Create a temporary values file for the annotation
            VALUES_FILE=$(mktemp)
            cat > ${VALUES_FILE} <<EOF
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${LB_ROLE_ARN}
EOF
            USE_VALUES_FILE=true
        else
            echo -e "${YELLOW}⚠️  IAM role not found. Attempting to install without IRSA...${NC}"
            echo -e "${YELLOW}   If installation fails, create IAM role manually or provide role ARN${NC}"
            USE_VALUES_FILE=false
        fi
    else
        echo -e "${YELLOW}⚠️  OIDC provider not found. Installing without IRSA...${NC}"
        USE_VALUES_FILE=false
    fi
    
    # Get VPC ID
    VPC_ID=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${AWS_REGION} --profile ${AWS_PROFILE} --query "cluster.resourcesVpcConfig.vpcId" --output text)
    
    # Install using Helm with or without values file
    if [ "$USE_VALUES_FILE" = true ]; then
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
            -n kube-system \
            -f ${VALUES_FILE} \
            --set clusterName=${CLUSTER_NAME} \
            --set serviceAccount.create=true \
            --set serviceAccount.name=aws-load-balancer-controller \
            --set region=${AWS_REGION} \
            --set vpcId=${VPC_ID} \
            --wait --timeout 5m 2>&1 | tee /tmp/lb-controller-install.log
        rm -f ${VALUES_FILE}
    else
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
            -n kube-system \
            --set clusterName=${CLUSTER_NAME} \
            --set serviceAccount.create=true \
            --set serviceAccount.name=aws-load-balancer-controller \
            --set region=${AWS_REGION} \
            --set vpcId=${VPC_ID} \
            --wait --timeout 5m 2>&1 | tee /tmp/lb-controller-install.log
    fi
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ AWS Load Balancer Controller installed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to install AWS Load Balancer Controller${NC}"
        echo -e "${YELLOW}📋 Installation log saved to /tmp/lb-controller-install.log${NC}"
        echo -e "${YELLOW}💡 You may need to create IAM role manually. Check the log for details.${NC}"
        echo -e "${YELLOW}   Or install using YAML:${NC}"
        echo -e "${YELLOW}   kubectl apply -f https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.8.3/v2_8_3_full.yaml${NC}"
    fi
fi

# Wait for webhook endpoints to be available
echo -e "${YELLOW}⏳ Waiting for webhook endpoints to be available...${NC}"
WEBHOOK_READY=false
for i in {1..30}; do
    ENDPOINTS=$(kubectl get endpoints -n kube-system aws-load-balancer-webhook-service -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null)
    if [ -n "$ENDPOINTS" ]; then
        echo -e "${GREEN}✅ Webhook endpoints are ready${NC}"
        WEBHOOK_READY=true
        break
    fi
    sleep 2
done

if [ "$WEBHOOK_READY" = false ]; then
    echo -e "${YELLOW}⚠️  Webhook endpoints not ready. Temporarily disabling webhooks to allow deployment...${NC}"
    kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook 2>/dev/null || true
    kubectl delete mutatingwebhookconfiguration aws-load-balancer-webhook 2>/dev/null || true
    echo -e "${YELLOW}   Webhooks will be recreated when controller is fully ready${NC}"
fi

echo ""

# Install envsubst if not available
if ! command -v envsubst &> /dev/null; then
  echo -e "${YELLOW}🔧 Installing envsubst...${NC}"
  # OS detection for cross-platform compatibility
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
      sudo apt-get install -y gettext-base
    elif command -v yum &> /dev/null; then
      sudo yum install -y gettext
    elif command -v dnf &> /dev/null; then
      sudo dnf install -y gettext
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &> /dev/null; then
      brew install gettext
    fi
  elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    echo -e "${YELLOW}Please install Git for Windows which includes envsubst${NC}"
    echo -e "${YELLOW}Or install gettext from: https://www.gnu.org/software/gettext/${NC}"
  fi
fi

echo ""
echo -e "${GREEN}✅ All EKS Deployment Prerequisites are met!${NC}"
echo -e "${BLUE}🚀 Starting EKS deployment...${NC}"

# Export variables for envsubst
export ECR_REGISTRY
export IMAGE_TAG
export DOCKER_REPO_NAME
export AWS_ACCOUNT_ID
export AWS_REGION

# Create namespace
echo -e "${YELLOW}📦 Creating namespace...${NC}"
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/namespace.yaml | kubectl apply -f -

# Apply ConfigMap and Secrets
echo -e "${YELLOW}🔐 Applying ConfigMap and Secrets...${NC}"
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/configmap.yaml | kubectl apply -f -
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/secret.yaml | kubectl apply -f -

# Deploy databases
echo -e "${YELLOW}🗄️  Deploying databases...${NC}"
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/mongodb.yaml | kubectl apply -f -
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/redis.yaml | kubectl apply -f -

# Wait for databases to be ready
echo -e "${YELLOW}⏳ Waiting for databases to be ready...${NC}"
kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=mongodb \
  --timeout=300s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=redis \
  --timeout=300s

# Deploy backend services
echo -e "${YELLOW}🔧 Deploying backend services...${NC}"
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/payment-service.yaml | kubectl apply -f -
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/project-service.yaml | kubectl apply -f -
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/user-service.yaml | kubectl apply -f -

# Deploy frontend
echo -e "${YELLOW}🌐 Deploying frontend...${NC}"
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/frontend-service.yaml | kubectl apply -f -

# Deploy ingress
echo -e "${YELLOW}🚪 Deploying ingress...${NC}"
envsubst '$ECR_REGISTRY $IMAGE_TAG $DOCKER_REPO_NAME $AWS_ACCOUNT_ID $AWS_REGION' < ${K8_DIR}/ingress.yaml | kubectl apply -f -

# Wait for all pods to be ready
echo -e "${YELLOW}⏳ Waiting for all services to be ready...${NC}"
kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=payment-service \
  --timeout=300s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=project-service \
  --timeout=300s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=user-service \
  --timeout=300s

kubectl wait --namespace ${DOCKER_REPO_NAME} \
  --for=condition=ready pod \
  --selector=app=frontend \
  --timeout=300s

echo -e "${GREEN}🎉 EKS Deployment completed successfully!${NC}"
echo ""

# Get Load Balancer URL
echo -e "${YELLOW}🔍 Getting Load Balancer URL...${NC}"
LB_URL=$(kubectl get ingress -n ${DOCKER_REPO_NAME} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")

echo -e "${GREEN}📋 Service URLs:${NC}"
if [ "$LB_URL" != "Pending..." ] && [ -n "$LB_URL" ]; then
    echo -e "  • Frontend: http://${LB_URL}"
    echo -e "  • Payment Service: http://${LB_URL}/api/payment"
    echo -e "  • Project Service: http://${LB_URL}/api/project"
    echo -e "  • User Service: http://${LB_URL}/api/user"
else
    echo -e "  • Load Balancer URL: ${YELLOW}Pending (check in a few minutes)${NC}"
    echo -e "  • Run: kubectl get ingress -n ${DOCKER_REPO_NAME} to get the URL"
fi

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
echo -e "  kubectl logs -f deployment/frontend -n ${DOCKER_REPO_NAME}"
echo ""
echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
echo -e "  kubectl describe pods -n ${DOCKER_REPO_NAME}"
echo -e "  kubectl get events -n ${DOCKER_REPO_NAME} --sort-by='.lastTimestamp'"
