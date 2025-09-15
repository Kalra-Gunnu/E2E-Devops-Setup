# 📁 Project Structure Overview

## 🏗️ Complete Application Architecture

```
E2E-Devops-Setup/
├── 📁 backend/                          # Backend Microservices
│   ├── 📁 paymentService/              # Payment Processing Service
│   │   ├── 📁 controllers/             # Business Logic Controllers
│   │   ├── 📁 models/                  # Data Models
│   │   ├── 📁 routes/                  # API Routes
│   │   ├── 📁 utils/                   # Utility Functions
│   │   ├── 📄 Dockerfile               # Container Configuration
│   │   ├── 📄 .dockerignore            # Docker Ignore Rules
│   │   ├── 📄 package.json             # Dependencies & Scripts
│   │   └── 📄 index.js                 # Service Entry Point
│   │
│   ├── 📁 projectService/              # Project Management Service
│   │   ├── 📁 controllers/             # Business Logic Controllers
│   │   ├── 📁 models/                  # Data Models
│   │   ├── 📁 routes/                  # API Routes
│   │   ├── 📁 utils/                   # Utility Functions
│   │   ├── 📄 Dockerfile               # Container Configuration
│   │   ├── 📄 .dockerignore            # Docker Ignore Rules
│   │   ├── 📄 package.json             # Dependencies & Scripts
│   │   └── 📄 index.js                 # Service Entry Point
│   │
│   └── 📁 userService/                 # User Management Service
│       ├── 📁 controllers/             # Business Logic Controllers
│       ├── 📁 models/                  # Data Models
│       ├── 📁 routes/                  # API Routes
│       ├── 📁 utils/                   # Utility Functions
│       ├── 📄 Dockerfile               # Container Configuration
│       ├── 📄 .dockerignore            # Docker Ignore Rules
│       ├── 📄 package.json             # Dependencies & Scripts
│       └── 📄 index.js                 # Service Entry Point
│
├── 📁 frontend/                         # Frontend Application
│   ├── 📁 template/                    # HTML Templates & Assets
│   │   ├── 📁 assets/                  # CSS, JS, Images
│   │   ├── 📄 index.html               # Main Landing Page
│   │   ├── 📄 about.html               # About Page
│   │   ├── 📄 contact.html             # Contact Page
│   │   └── 📄 course_details.html      # Course Details Page
│   └── 📁 testingUI/                   # Testing Interface
│
├── 📁 k8s/                             # Kubernetes Manifests
│   ├── 📄 namespace.yaml               # Application Namespace
│   ├── 📄 configmap.yaml               # Configuration Variables
│   ├── 📄 secret.yaml                  # Sensitive Data
│   ├── 📄 mongodb.yaml                 # MongoDB Deployment
│   ├── 📄 redis.yaml                   # Redis Deployment
│   ├── 📄 payment-service.yaml         # Payment Service Deployment
│   ├── 📄 project-service.yaml         # Project Service Deployment
│   ├── 📄 user-service.yaml            # User Service Deployment
│   ├── 📄 frontend-service.yaml        # Frontend Service
│   └── 📄 ingress.yaml                 # Ingress Configuration
│
├── 📄 docker-build-push.sh             # Docker Build & Push Script
├── 📄 deploy.sh                        # Kubernetes Deployment Script
├── 📄 complete_deployment.sh           # Complete Setup Script
├── 📄 SETUP_GUIDE.md                   # Detailed Setup Instructions
├── 📄 PROJECT_STRUCTURE.md             # This File
├── 📄 Readme.md                        # Project Overview
└── 📄 .gitignore                       # Git Ignore Rules
```

## 🐳 Docker Images Structure

| Service | Image Name | Port | Description |
|---------|------------|------|-------------|
| **Payment Service** | `<user-name>/e2e-devops/payment-service:latest` | 3000 | Handles payment processing, Razorpay integration |
| **Project Service** | `<user-name>/e2e-devops/project-service:latest` | 3001 | Manages projects, content, and S3 file storage |
| **User Service** | `<user-name>/e2e-devops/user-service:latest` | 3002 | User management and lead generation |

## ☸️ Kubernetes Resources

### Namespace
- **`e2e-devops`** - Isolated environment for the application

### Deployments
- **Frontend** - Nginx serving static files (1 replica)
- **Payment Service** - Payment processing (2 replicas)
- **Project Service** - Project management (2 replicas)
- **User Service** - User management (2 replicas)
- **MongoDB** - Primary database (1 replica)
- **Redis** - Caching layer (1 replica)

### Services
- **ClusterIP** services for internal communication
- **Ingress** for external access and routing

### Storage
- **PersistentVolumeClaims** for MongoDB and Redis data persistence

## 🔧 Scripts Overview

### 1. `docker-build-push.sh`
- Builds Docker images for all backend services
- Pushes images to DockerHub under `${DOCKER_USERNAME}/e2e-devops/`
- Includes error handling and status reporting

### 2. `deploy.sh`
- Deploys complete application to Kubernetes
- Manages deployment order and dependencies
- Waits for services to be ready
- Provides deployment status and access URLs

### 3. `complete_deployment.sh`
- Complete automation script
- Checks prerequisites
- Runs build, push, and deployment in sequence
- Provides comprehensive setup feedback

## 🌐 Service Endpoints

| Endpoint | Service | Description |
|----------|---------|-------------|
| `/` | Frontend | Main application interface |
| `/api/payment/*` | Payment Service | Payment processing APIs |
| `/api/project/*` | Project Service | Project management APIs |
| `/api/user/*` | User Service | User management APIs |
| `/health` | All Services | Health check endpoints |

## 🔐 Configuration Management

### ConfigMap (`k8s/configmap.yaml`)
- Non-sensitive configuration variables
- Environment-specific settings
- Service endpoints and regions

### Secret (`k8s/secret.yaml`)
- Database connection strings
- API keys and tokens
- AWS credentials
- Base64 encoded for security

## 📊 Monitoring & Health Checks

### Health Endpoints
- **`/health`** - Service status and uptime
- **Liveness Probes** - Container health monitoring
- **Readiness Probes** - Service availability checks

### Resource Limits
- **CPU**: 250m-500m per service
- **Memory**: 256Mi-512Mi per service
- **Storage**: 1Gi for MongoDB, 512Mi for Redis

## 🚀 Deployment Flow

```
1. Build Docker Images → 2. Push to DockerHub → 3. Enable Kubernetes in Docker Desktop → 4. Deploy Infrastructure → 5. Deploy Services → 6. Configure Ingress → 7. Verify Deployment
```

## 🔍 Troubleshooting Resources

- **Logs**: `kubectl logs -f deployment/[service-name] -n e2e-devops`
- **Status**: `kubectl get pods -n e2e-devops`
- **Services**: `kubectl get services -n e2e-devops`
- **Dashboard**: `kubectl proxy` then visit Kubernetes dashboard

---

**This structure provides a complete, production-ready microservices architecture with automated deployment and monitoring capabilities.**
