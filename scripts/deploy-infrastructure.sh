#!/bin/bash

# Terraform Infrastructure Deployment Script
# This script deploys the complete infrastructure in the correct order

set -e

echo "🚀 Starting Terraform Infrastructure Deployment"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    print_error "AWS CLI is not configured or credentials are invalid"
    echo "Please run: aws configure"
    exit 1
fi

print_status "AWS CLI is configured ✓"

# Step 1: Deploy Bootstrap (S3 Backend + DynamoDB)
echo ""
echo "📦 Step 1: Deploying Bootstrap Infrastructure"
echo "============================================="

cd infra/terraform/bootstrap

print_status "Initializing Terraform for bootstrap..."
terraform init

print_status "Planning bootstrap deployment..."
terraform plan -var-file="terraform.tfvars"

print_warning "About to create S3 bucket and DynamoDB table for Terraform state management"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Bootstrap deployment cancelled"
    exit 1
fi

print_status "Applying bootstrap configuration..."
terraform apply -var-file="terraform.tfvars" -auto-approve

print_status "Bootstrap infrastructure deployed successfully ✓"

# Step 2: Deploy Dev Environment (Two-stage deployment)
echo ""
echo "🏗️  Step 2: Deploying Dev Environment"
echo "====================================="

cd ../envs/dev

print_status "Initializing Terraform with S3 backend..."
terraform init -backend-config="backend.hcl"

# Deploy all infrastructure components
print_status "Planning complete infrastructure deployment..."
terraform plan -var-file="terraform.tfvars"

print_warning "About to deploy:"
echo "  - VPC with public/private subnets"
echo "  - ECR repositories for 4 services"
echo "  - EKS cluster with cost-optimized node groups"

read -p "Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Deployment cancelled"
    exit 1
fi

print_status "Applying infrastructure configuration..."
terraform apply -var-file="terraform.tfvars" -auto-approve

print_status "Dev environment deployed successfully ✓"

# Step 3: Configure kubectl
#echo ""
#echo "⚙️  Step 3: Configuring kubectl"
#echo "==============================="

#print_status "Updating kubeconfig for EKS cluster..."
#aws eks update-kubeconfig --region us-west-2 --name app-dev

#print_status "Testing cluster connectivity..."
#kubectl get nodes

#print_status "kubectl configured successfully ✓"

# Step 4: Display outputs
echo ""
echo "📋 Deployment Summary"
echo "===================="

print_status "Getting Terraform outputs..."
terraform output

echo ""
print_status "🎉 Infrastructure deployment completed successfully!"
echo ""
echo "Next steps:"
echo "1. Push your Docker images to the ECR repositories"
#echo "2. Deploy your Kubernetes manifests from the k8s/ directory"
#echo "3. Configure your applications to use the deployed resources"
echo ""
echo "Useful commands:"
#echo "  - View EKS cluster: aws eks describe-cluster --name app-dev --region us-west-2"
echo "  - List ECR repositories: aws ecr describe-repositories --region us-west-2"
#echo "  - Get cluster nodes: kubectl get nodes"
#echo "  - View all resources: kubectl get all --all-namespaces"
