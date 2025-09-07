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

    stage('Bootstrap Backend (Run Once)') {
      // This stage only runs if the commit message contains '[bootstrap]'
      when {
          expression { return git.currentCommit.message.contains('[bootstrap]') }
      }
      steps {
        dir('infra/terraform/bootstrap') {
          // Initialize with the specific backend for the bootstrap state
          sh """
              terraform init \\
                  -backend-config="bucket=${env.TF_BACKEND_BUCKET}" \\
                  -backend-config="key=bootstrap/terraform.tfstate" \\
                  -backend-config="region=${env.AWS_DEFAULT_REGION}"
          """
          
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

    stage('Plan Production') {
      when { 
        branch 'main' 
      }
      steps {
        dir('infra/terraform/envs/prod') {
          sh """
            terraform init \\
                -backend-config="bucket=${env.TF_BACKEND_BUCKET}" \\
                -backend-config="key=prod/terraform.tfstate" \\
                -backend-config="region=${env.TF_BACKEND_REGION}"
          """
          // Step 1: Create the plan file
          sh 'terraform plan -var-file=terraform.tfvars -out=prod.tfplan'

          // Step 2: Convert the plan to JSON and check for destructions
          sh '''
            #!/bin/bash
            set -e
            
            # Convert plan to JSON
            terraform show -json prod.tfplan > prod.json
            
            # Check for any actions that are "delete"
            # The 'jq' tool is excellent for parsing JSON in shell scripts
            deletions=$(jq -r '[.resource_changes[] | select(.change.actions[] == "delete")] | length' prod.json)
            
            echo "Plan includes $deletions resource(s) to be destroyed."
            
            if [ "$deletions" -gt 0 ]; then
                echo "ERROR: Destructive changes detected in Terraform plan. Failing build."
                exit 1
            fi
          '''
        }
      }
    }

    stage('Apply Production') {
      // This stage will now only run if the 'Plan Production' stage succeeds
      // (i.e., no destructive changes were found).
      when { branch 'main' }
      steps {
        dir('infra/terraform/envs/prod') {
            input "Plan is safe (no destructions). Proceed with applying to production?"
            sh 'terraform apply -auto-approve prod.tfplan'
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
