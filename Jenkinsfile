pipeline {
  agent any

  environment {
    AWS_REGION = "${env.AWS_REGION}"
    AWS_ACCOUNT_ID = "${env.AWS_ACCOUNT_ID}"
    AWS_ACCESS_KEY_ID = "${env.AWS_ACCESS_KEY_ID}"
    AWS_SECRET_ACCESS_KEY = "${env.AWS_SECRET_ACCESS_KEY}"
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

    stage("PreRequisites") {
      steps {
        dir("scripts") {
          sh "chmod +x 0-install-prerequisites.sh"
          sh "./0-install-prerequisites.sh"
        }
      }
    }

    stage("Build & Dockerize") {
      steps {
        dir("scripts") {
          sh "chmod +x 1-docker-build-push.sh"
          sh "./1-docker-build-push.sh ${IMAGE_TAG} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}"
        }
      }
    }

    stage("Scan Images (Trivy)") {
      steps {
        dir("scripts") {
          sh "chmod +x 2-trivy-scan-all.sh"
          sh "./2-trivy-scan-all.sh ${IMAGE_TAG} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}"
          archiveArtifacts artifacts: 'trivy-scan-results.txt', onlyIfSuccessful: false
        }
      }
    }

    stage("Deploy Infrastructure") {
      when { 
        branch 'main' 
      }
      steps {
        dir("scripts") {
          script {
            // Make the script executable
            sh "chmod +x deploy-infrastructure.sh"
            
            // For CI/CD, we need to modify the script to run non-interactively
            // Create a non-interactive version for Jenkins
            sh '''
              # Create a non-interactive version of the deploy script
              cp deploy-infrastructure.sh deploy-infrastructure-ci.sh
              
              # Replace interactive prompts with automatic "yes" responses
              sed -i 's/read -p "Continue? (y\/N): " -n 1 -r/REPLY="y"/g' deploy-infrastructure-ci.sh
              sed -i 's/read -p "Continue with Stage 1 deployment? (y\/N): " -n 1 -r/REPLY="y"/g' deploy-infrastructure-ci.sh
              sed -i 's/read -p "Continue with Stage 2 deployment? (y\/N): " -n 1 -r/REPLY="y"/g' deploy-infrastructure-ci.sh
              
              # Make it executable
              chmod +x deploy-infrastructure-ci.sh
            '''
            
            // Run the modified script
            sh "./deploy-infrastructure-ci.sh"
          }
        }
      }
    }
    
    stage("Push to ECR") {
      steps {
        dir("scripts") {
          sh "chmod +x 3-ecr-push-all-images.sh"
          sh "./3-ecr-push-all-images.sh ${AWS_REGION} ${AWS_ACCOUNT_ID} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}"
        }
      }
    }

    stage("Deploy to EKS") {
      steps {
        dir("scripts") {
          sh "chmod +x 4-deploy-eks-cluster.sh"
          sh "./4-deploy-eks-cluster.sh ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_REPO_NAME}"
        }
      }
    }

    stage("Notify") {
      steps {
        echo "✅ Pipeline completed successfully!"
        echo "🚀 Infrastructure deployed and applications running on EKS"
        // Add slackSend/email notification if configured
      }
    }
  }

  post {
    always {
      // Clean up temporary files
      sh 'rm -f scripts/deploy-infrastructure-ci.sh || true'
    }
    success {
      echo "🎉 Pipeline completed successfully!"
    }
    failure {
      echo "❌ Pipeline failed!"
      // Add slackSend/email notification if configured
    }
  }
}
