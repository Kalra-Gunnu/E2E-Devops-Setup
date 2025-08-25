# 🚀 E2E DevOps Fullstack Application Setup Guide

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** - [Install Docker](https://docs.docker.com/get-docker/)
- **Minikube** - [Install Minikube](https://minikube.sigs.k8s.io/docs/start/)
- **kubectl** - [Install kubectl](https://kubernetes.io/docs/tasks/tools/)
- **Node.js** (v18 or higher) - [Install Node.js](https://nodejs.org/)

## 🔧 Step-by-Step Setup

### 1. Clone and Navigate to Project
```bash
cd /Users/pragoy/projects/vlearn/E2E-Devops-Setup
```

### 2. Login to DockerHub
```bash
docker login
# Enter your DockerHub credentials (<your docker hub user>)
```

### 3. Build and Push Docker Images
```bash
# Make the script executable
chmod +x docker-build-push.sh

# Run the build and push script
./docker-build-push.sh
```

This will:
- Build all backend services
- Push them to DockerHub under `<your docker hub user>/e2e-devops/`
- Create images: `payment-service`, `project-service`, `user-service`

### 4. Start Minikube
```bash
# Start minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --disk-size=20g

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
```

### 5. Deploy to Kubernetes
```bash
# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Ingress       │    │   Backend       │
│   (Nginx)       │◄───┤   Controller    │◄───┤   Services      │
│   Port: 80      │    │                 │    │   Ports: 3000+  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Databases     │
                       │ MongoDB + Redis │
                       └─────────────────┘
```

## 📊 Services

| Service | Port | Image | Replicas |
|---------|------|-------|----------|
| Frontend | 80 | nginx:alpine | 1 |
| Payment Service | 3000 | <your docker hub user>/e2e-devops/payment-service:latest | 2 |
| Project Service | 3001 | <your docker hub user>/e2e-devops/project-service:latest | 2 |
| User Service | 3002 | <your docker hub user>/e2e-devops/user-service:latest | 2 |
| MongoDB | 27017 | mongo:6.0 | 1 |
| Redis | 6379 | redis:7-alpine | 1 |

## 🌐 Access URLs

After deployment, access your application at:

- **Frontend**: http://[MINIKUBE_IP]
- **Payment API**: http://[MINIKUBE_IP]/api/payment
- **Project API**: http://[MINIKUBE_IP]/api/project
- **User API**: http://[MINIKUBE_IP]/api/user

Get Minikube IP:
```bash
minikube ip
```

## 🔍 Monitoring and Debugging

### Check Pod Status
```bash
kubectl get pods -n e2e-devops
kubectl get services -n e2e-devops
kubectl get ingress -n e2e-devops
```

### View Logs
```bash
# Payment Service
kubectl logs -f deployment/payment-service -n e2e-devops

# Project Service
kubectl logs -f deployment/project-service -n e2e-devops

# User Service
kubectl logs -f deployment/user-service -n e2e-devops

# Frontend
kubectl logs -f deployment/frontend -n e2e-devops
```

### Access Pod Shell
```bash
kubectl exec -it [POD_NAME] -n e2e-devops -- /bin/sh
```

## 🧹 Cleanup

### Remove Application
```bash
kubectl delete namespace e2e-devops
```

### Stop Minikube
```bash
minikube stop
minikube delete
```

## 🔐 Environment Variables

Update the following files with your actual values:

1. **`k8s/secret.yaml`** - Update base64 encoded secrets
2. **`k8s/configmap.yaml`** - Update configuration values

### Generate Base64 Secrets
```bash
echo -n "your-actual-value" | base64
```

## 🚨 Troubleshooting

### Common Issues

1. **Images not found**: Ensure Docker images are built and pushed
2. **Pods not starting**: Check resource limits and environment variables
3. **Services not accessible**: Verify ingress controller is running
4. **Database connection issues**: Check MongoDB and Redis pod status

### Useful Commands
```bash
# Check minikube status
minikube status

# Check addons
minikube addons list

# View minikube dashboard
minikube dashboard

# Check ingress controller
kubectl get pods -n ingress-nginx
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

## 🎯 Next Steps

1. **Customize Environment Variables** - Update secrets and configs
2. **Add Monitoring** - Integrate Prometheus and Grafana
3. **Set up CI/CD** - Automate deployment pipeline
4. **Add Load Balancing** - Configure horizontal pod autoscaling
5. **Security Hardening** - Implement network policies and RBAC

---

**Happy Deploying! 🚀**
