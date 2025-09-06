pipeline {
  agent any

  environment {
    AWS_REGION = "${env.AWS_REGION}"
    ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_DEFAULT_REGION}.amazonaws.com"
    DOCKER_USERNAME = "${env.DOCKER_USERNAME}"
    DOCKER_REPO_NAME = "${env.DOCKER_REPO_NAME}"
    IMAGE_TAG = "${env.BUILD_NUMBER}"
  }

  stages {
    stage("Checkout") {
      steps {
        checkout scm
      }
    }

    stage("Build & Dockerize") {
      steps {
        dir("scripts") {
          sh "1-docker-build-push.sh ${IMAGE_TAG} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}"
        }
      }
    }

    stage("Scan Images (Trivy)") {
      steps {
        dir("scripts") {
          sh "2-trivy-scan-all.sh ${IMAGE_TAG} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}"
        }
      }
    }

    stage("Push to ECR") {
      steps {
        dir("scripts") {
          sh "3-ecr-push-all-images.sh ${AWS_REGION} ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}"
        }
      }
    }

    stage("Terraform Plan/Apply") {
      when { branch "main" }
      steps {
        dir("infra/terraform/bootstrap") {
          sh "terraform init -backend-config=backend.conf"
          sh "terraform plan -out=tfplan"
          sh "terraform apply -auto-approve tfplan"
        }
        dir("infra/terraform/envs/prod") {
          sh "terraform init -backend-config=backend.conf"
          sh "terraform plan -out=tfplan"
          sh "terraform apply -auto-approve tfplan"
        }
      }
    }

    stage("Deploy to Kubernetes") {
      steps {
        dir("scripts") {
          sh "4-deploy-kube-cluster.sh ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_REPO_NAME}"
        }
      }
    }

    stage("Notify") {
      steps {
        echo "Send Slack/Email notifications here"
      }
    }
  }

  post {
    failure {
      echo "Pipeline failed 🚨"
      // Add slackSend/email notification if configured
    }
  }
}
