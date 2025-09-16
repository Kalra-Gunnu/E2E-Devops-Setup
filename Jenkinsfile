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
          sh "0-install-prerequisites.sh"
        }
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

    stage('Bootstrap Backend (Run Once)') {
      // This stage only runs if the commit message contains '[bootstrap]'
      when {
          expression { return git.currentCommit.message.contains('[bootstrap]') }
      }
      steps {
        dir('infra/terraform/bootstrap') {
          // Initialize with the specific backend for the bootstrap state
          sh 'terraform init'
          
          // Create the plan
          sh 'terraform plan -out=tfplan'

          // --- Automated Safety Check ---
          // This script fails the build if any resource is planned for modification or deletion.
          sh '''
              #!/bin/bash
              set -e
              
              # Convert the plan to a machine-readable JSON format
              terraform show -json tfplan > tfplan.json
              
              # Use 'jq' to count how many resource changes are NOT "create" actions.
              # This includes "update", "delete", and "replace" (delete-before-create).
              non_create_actions=$(jq -r '[.resource_changes[] | select(.change.actions | contains(["create"]) | not)] | length' tfplan.json)
              
              echo "Plan contains $non_create_actions resource(s) to be modified or destroyed."

              # If there are ANY non-create actions, fail the build.
              if [ "$non_create_actions" -gt 0 ]; then
                  echo "ERROR: The bootstrap plan contains modifications or deletions, which is not allowed."
                  echo "Bootstrap infrastructure should be immutable. Failing build."
                  exit 1
              else
                  echo "Plan is safe. Only create actions were found."
              fi
          '''
          
          // This apply command will only run if the safety check above passes.
          echo "Proceeding with automatic apply for bootstrap creation."
          sh 'terraform apply -auto-approve tfplan'
        }
      }
    }

    stage('Plan Development - Stage 1') {
      when { 
        branch 'main' 
      }
      steps {
        dir('infra/terraform/envs/dev') {
          sh """
            terraform init  -backend-config="backend.hcl"
          """
          // Step 1: Create the plan file for VPC, ECR, EKS
          sh 'terraform plan -target="module.vpc" -target="module.ecr" -target="module.eks" -out="stage1.tfplan"'

          // Step 2: Convert the plan to JSON and check for destructions
          sh '''
            #!/bin/bash
            set -e
            
            # Convert plan to JSON
            terraform show -json stage1.tfplan > stage1.json
            
            # Check for any actions that are "delete"
            deletions=$(jq -r '[.resource_changes[] | select(.change.actions[] == "delete")] | length' stage1.json)
            
            echo "Stage 1 plan includes $deletions resource(s) to be destroyed."
            
            if [ "$deletions" -gt 0 ]; then
                echo "ERROR: Destructive changes detected in Terraform plan. Failing build."
                exit 1
            fi
          '''
        }
      }
    }

    stage('Apply Development - Stage 1') {
      when { branch 'main' }
      steps {
        dir('infra/terraform/envs/dev') {
            input "Stage 1 plan is safe (no destructions). Proceed with applying VPC, ECR, EKS?"
            sh 'terraform apply -auto-approve stage1.tfplan'
        }
      }
    }

    stage('Plan Development - Stage 2 (IAM IRSA)') {
      when { branch 'main' }
      steps {
        dir('infra/terraform/envs/dev') {
          // Plan IAM IRSA after EKS is created
          sh 'terraform plan -target="module.iam_irsa" -out="stage2.tfplan"'
          
          sh '''
            #!/bin/bash
            set -e
            
            # Convert plan to JSON
            terraform show -json stage2.tfplan > stage2.json
            
            # Check for any actions that are "delete"
            deletions=$(jq -r '[.resource_changes[] | select(.change.actions[] == "delete")] | length' stage2.json)
            
            echo "Stage 2 plan includes $deletions resource(s) to be destroyed."
            
            if [ "$deletions" -gt 0 ]; then
                echo "ERROR: Destructive changes detected in IAM IRSA plan. Failing build."
                exit 1
            fi
          '''
        }
      }
    }

    stage('Apply Development - Stage 2 (IAM IRSA)') {
      when { branch 'main' }
      steps {
        dir('infra/terraform/envs/dev') {
            input "Stage 2 plan is safe. Proceed with applying IAM IRSA?"
            sh 'terraform apply -auto-approve stage2.tfplan'
        }
      }
    }
    
    stage("Push to ECR") {
      steps {
        dir("scripts") {
          sh "3-ecr-push-all-images.sh ${AWS_REGION} ${AWS_ACCOUNT_ID} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_USERNAME} ${DOCKER_REPO_NAME}"
        }
      }
    }
    
    stage("Set up Kubeconfig") {
      steps {
        dir("infra/terraform/envs/dev") {
          // Extract cluster name and region from Terraform outputs
          script {
            env.CLUSTER_NAME = sh(script: "terraform output -raw cluster_name", returnStdout: true).trim()
            env.AWS_REGION = sh(script: "terraform output -raw region", returnStdout: true).trim()
          }
        }
        // Update kubeconfig to point to the new EKS cluster
        sh '''
          aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
        '''
      }
    }


    stage("Deploy to EKS") {
      steps {
        dir("scripts") {
          sh "4-deploy-eks-cluster.sh ${IMAGE_TAG} ${ECR_REGISTRY} ${DOCKER_REPO_NAME}"
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
