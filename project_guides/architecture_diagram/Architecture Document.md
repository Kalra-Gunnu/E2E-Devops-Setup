# App Architecture

---

## **AWS EKS Architecture for MERN Application**
### **Overview**
This architecture diagram illustrates the deployment of a MERN-based application (React frontend + 3 backend microservices) on **Amazon EKS,** utilizing AWS-managed services for scalability, security, and reliability.
 The backend services are:

1. **paymentService**
2. **projectService**
3. **userService**
The application also integrates with **Razorpay** for payments, **MongoDB Atlas** for database services, and **Redis Cache** for performance optimization.

---

### **Workflow**
1. **External User Access**
    - Users access the application via a public **AWS Application Load Balancer (ALB)**.
    - ALB uses the **AWS Load Balancer Controller** (Ingress) to route traffic to the appropriate Kubernetes services in the EKS cluster.
2. **Frontend**
    - Frontend static assets are deployed to **CloudFront CDN** for global distribution and low-latency access.
    - Backend API requests from the frontend are routed via ALB → Ingress → EKS backend deployments.
3. **Backend Services (Deployments)**
    - **projectService**, **paymentService**, and **userService** are deployed as separate Kubernetes Deployments in EKS.
    - Each service runs in private subnets and communicates securely with external and AWS-managed resources.
    - All services pull container images from **Amazon ECR**.
4. **Secrets and Configurations**
    - Sensitive environment variables (Mongo URI, Razorpay keys, AWS keys, S3 bucket names) are stored in **AWS Secrets Manager**.
    - Services retrieve these secrets securely at runtime.
    - AWS service access is provided via **IAM Roles for Service Accounts (IRSA)** — no static credentials in code.
5. **File Storage**
    - Services store and retrieve files from an **Amazon S3 bucket**.
    - The bucket is accessed securely via IAM permissions.
6. **Database and External APIs**
    - All services that need persistence use **MongoDB Atlas** over a secure connection.
    - **paymentService** communicates with **Razorpay** APIs for payment processing.
    - **paymentService** optionally connects to **Redis Cache** for faster access to frequently used data.
7. **Networking**
    - ALB is deployed in **public subnets**.
    - EKS worker nodes (running pods) are deployed in **private subnets** for better security.
    - **NAT Gateway** allows private nodes to access the internet for updates and external APIs.
8. **CI/CD Pipeline**
    - **Jenkins** automates building, testing, and deploying services.
    - Images are built and pushed to **Amazon ECR**.
    - Jenkins triggers Helm/Kubernetes deployments to EKS.
9. **Observability**
    - Logs and metrics are collected via **Amazon CloudWatch** and Container Insights.
    - Monitoring provides visibility into performance, errors, and scaling needs.
---

### **Key AWS Services Used**
- **Amazon EKS** – Managed Kubernetes service.
- **Amazon ALB** – Load balancing with Ingress Controller.
- **Amazon ECR** – Private container registry.
- **Amazon S3** – File storage.
- **AWS Secrets Manager** – Secret storage.
- **AWS IAM (IRSA)** – Fine-grained AWS permissions to pods.
- **Amazon CloudFront** – CDN for frontend.
- **Amazon CloudWatch** – Logs and monitoring.
- **NAT Gateway** – Outbound internet for private subnets.
- **MongoDB Atlas** – Managed database.
- **Razorpay** – Payment gateway.
- **Redis Cache** – Caching layer.
---

### **Security Highlights**
- **Private subnets** for all application workloads.
- **TLS termination** at ALB using ACM certificates.
- **IAM Roles for Service Accounts (IRSA)** for AWS resource access without hardcoded credentials.
- **Secrets Manager** for all sensitive variables.


