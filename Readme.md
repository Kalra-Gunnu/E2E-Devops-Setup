# Devops - Capstone Project

## Problem Statement
Modern DevOps teams need a robust, automated CI/CD pipeline that not only builds and deploys
applications consistently but also ensures container security and Kubernetes cluster reliability. This
project sets up an end-to-end pipeline that covers infrastructure provisioning (Terraform),
configuration management (Ansible), containerization (Docker), CI/CD orchestration (Jenkins),
secure image scanning (Trivy), application deployment on AWS EKS, and automated cluster health
monitoring & self-healing using Prometheus and custom scripts.

---------------------------

## Project Goals
1. Design and implement an automated CI/CD pipeline on AWS.
2. Provision infrastructure using Terraform (VPC, subnets, EKS, EC2).
3. Automate configuration using Ansible.
4. Build and scan Docker images for vulnerabilities before deploying.
5. Deploy applications on Kubernetes (AWS EKS) for scalability and high availability.
6. Automate health checks and self-healing for Kubernetes clusters.
7. Set up real-time monitoring and alerting with Prometheus, Grafana, and Slack notifications.
---------------------------

## Key Tools & Technologies
- CI/CD: Jenkins, GitHub
- Containerization: Docker, AWS ECR
- Infrastructure as Code: Terraform
- Configuration Management: Ansible
- Orchestration: Kubernetes (AWS EKS)
- Image Security: Trivy (Container Vulnerability Scanner)
- Monitoring & Alerts: Prometheus, Grafana, Alertmanager, Slack API
- Programming/Scripting: Bash, Python (for health checker)
- Other AWS Services: CDN, EC2, ECS + Fargate
- Database: MONGO DB (Atlas Cloud)
---------------------------
