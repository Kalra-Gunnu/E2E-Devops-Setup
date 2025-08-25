#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Generating Kubernetes manifests with configurable image names...${NC}"

# Load configuration
if [ -f "config.env" ]; then
    source config.env
    echo -e "${GREEN}✅ Configuration loaded from config.env${NC}"
else
    echo -e "${YELLOW}⚠️  config.env not found, using default values${NC}"
    DOCKER_USERNAME="<your docker hub user>"
    DOCKER_REPO_NAME="e2e-devops"
fi

# Create k8s directory if it doesn't exist
mkdir -p k8s

# Generate payment service manifest
cat > k8s/payment-service.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: e2e-devops
  labels:
    app: payment-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
      - name: payment-service
        image: ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-payment-service:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: NODE_ENV
        - name: PORT
          value: "3000"
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: MONGODB_URI
        - name: RAZORPAY_KEY_ID
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: RAZORPAY_KEY_ID
        - name: RAZORPAY_KEY_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: RAZORPAY_KEY_SECRET
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: payment-service
  namespace: e2e-devops
  labels:
    app: payment-service
spec:
  selector:
    app: payment-service
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
  type: ClusterIP
EOF

# Generate project service manifest
cat > k8s/project-service.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project-service
  namespace: e2e-devops
  labels:
    app: project-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: project-service
  template:
    metadata:
      labels:
        app: project-service
    spec:
      containers:
      - name: project-service
        image: ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-project-service:latest
        ports:
        - containerPort: 3001
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: NODE_ENV
        - name: PORT
          value: "3001"
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: MONGODB_URI
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: REDIS_URL
        - name: AWS_REGION
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: AWS_REGION
        - name: AWS_S3_BUCKET
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: AWS_S3_BUCKET
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: AWS_ACCESS_KEY_ID
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: AWS_SECRET_ACCESS_KEY
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: project-service
  namespace: e2e-devops
  labels:
    app: project-service
spec:
  selector:
    app: project-service
  ports:
  - port: 3001
    targetPort: 3001
    protocol: TCP
  type: ClusterIP
EOF

# Generate user service manifest
cat > k8s/user-service.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: e2e-devops
  labels:
    app: user-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-user-service:latest
        ports:
        - containerPort: 3002
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: NODE_ENV
        - name: PORT
          value: "3002"
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: MONGODB_URI
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3002
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3002
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: e2e-devops
  labels:
    app: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 3002
    targetPort: 3002
    protocol: TCP
  type: ClusterIP
EOF

echo -e "${GREEN}✅ Kubernetes manifests generated successfully!${NC}"
echo -e "${GREEN}📋 Using Docker images:${NC}"
echo -e "  • ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-payment-service:latest"
echo -e "  • ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-project-service:latest"
echo -e "  • ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-user-service:latest"
echo ""
echo -e "${GREEN}🚀 Ready to deploy with custom image names!${NC}"
