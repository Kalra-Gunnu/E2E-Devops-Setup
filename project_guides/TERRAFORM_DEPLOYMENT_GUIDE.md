# Terraform Infrastructure Deployment Guide

## Issue Identified ⚠️
The IAM IRSA module has a dependency on EKS cluster outputs (`oidc_provider_url` and `oidc_provider_thumbprint`) that won't be available during the first `terraform plan`. This requires a **two-stage deployment approach**.

## Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform installed (v1.0+)
- kubectl installed

## Deployment Options

### Option 1: Automated Script (Recommended)
```bash
./deploy-infrastructure.sh
```
This script handles the two-stage deployment automatically.

### Option 2: Manual Two-Stage Deployment

#### Stage 1: Bootstrap Infrastructure
```bash
cd infra/terraform/bootstrap
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

#### Stage 2a: Core Infrastructure (VPC, ECR, EKS)
```bash
cd ../envs/dev
terraform init -backend-config="backend.hcl"

# Deploy only VPC, ECR, and EKS first
terraform plan -var-file="terraform.tfvars" -target=module.vpc -target=module.ecr -target=module.eks
terraform apply -var-file="terraform.tfvars" -target=module.vpc -target=module.ecr -target=module.eks
```

#### Stage 2b: IAM IRSA (After EKS is ready)
```bash
# Now deploy IAM IRSA with EKS outputs available
terraform plan -var-file="terraform.tfvars" -target=module.iam_irsa
terraform apply -var-file="terraform.tfvars" -target=module.iam_irsa
```

#### Stage 3: Configure kubectl
```bash
aws eks update-kubeconfig --region us-west-2 --name app-dev
kubectl get nodes
```

## Alternative: Fix the Dependency Issue

If you prefer a single-stage deployment, you can modify the IAM IRSA module to use `depends_on`:

```hcl
# In infra/terraform/envs/dev/main.tf
module "iam_irsa" {
  source = "../../modules/iam_irsa"
  
  # ... other variables ...
  
  depends_on = [module.eks]
}
```

## Infrastructure Components

### Bootstrap
- **S3 Bucket**: `g5-e2e-devops-bucket` (Terraform state)
- **DynamoDB Table**: `g5-e2e-devops-lock-table` (State locking)

### Dev Environment
- **VPC**: `app-dev-vpc` with public/private subnets across 3 AZs
- **ECR Repositories**: g5-slabai-payment, g5-slabai-project, g5-slabai-user, g5-slabai-frontend
- **EKS Cluster**: `app-dev` with cost-optimized node groups
- **IAM IRSA**: Service accounts for external secrets

## Cost Estimation
- **Dev Environment**: ~$50-80/month
  - EKS Control Plane: ~$73/month
  - EC2 Instances (t3.small): ~$15-30/month
  - NAT Gateway: ~$45/month
  - Other resources: ~$5-10/month

## Post-Deployment Steps
1. **Push Docker Images to ECR**:
   ```bash
   # Get ECR login token
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
   
   # Tag and push images (updated repository names)
   docker tag payment:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/g5-slabai-payment:latest
   docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/g5-slabai-payment:latest
   
   docker tag project:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/g5-slabai-project:latest
   docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/g5-slabai-project:latest
   
   docker tag user:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/g5-slabai-user:latest
   docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/g5-slabai-user:latest
   
   docker tag frontend:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/g5-slabai-frontend:latest
   docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/g5-slabai-frontend:latest
   ```

2. **Deploy Kubernetes Manifests**:
   ```bash
   kubectl apply -f k8s/
   ```

3. **Verify Deployment**:
   ```bash
   kubectl get all --all-namespaces
   kubectl get nodes
   ```

## Troubleshooting

### Common Issues
1. **OIDC Provider Error**: Use two-stage deployment as described above
2. **AWS Credentials**: Ensure `aws sts get-caller-identity` works
3. **Region Mismatch**: All resources are configured for `us-west-2`
4. **State Lock**: If state is locked, check DynamoDB table for stuck locks

### Useful Commands
```bash
# View EKS cluster details
aws eks describe-cluster --name app-dev --region us-west-2

# List ECR repositories (updated names)
aws ecr describe-repositories --region us-west-2 --repository-names g5-slabai-payment g5-slabai-project g5-slabai-user g5-slabai-frontend

# Get cluster nodes
kubectl get nodes

# View Terraform outputs
terraform output

# Destroy infrastructure (if needed)
terraform destroy -var-file="terraform.tfvars"
```

## Security Notes
- S3 bucket has versioning and encryption enabled
- Public access is blocked on the state bucket
- EKS cluster uses private subnets for worker nodes
- IAM roles follow least privilege principle
