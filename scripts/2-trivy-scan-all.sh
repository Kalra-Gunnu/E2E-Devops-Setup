#!/usr/bin/env bash
set -euo pipefail

TAG=${1:-latest}
DOCKER_USERNAME=${2:-}
DOCKER_REPO_NAME=${3:-e2e-devops}

OUTPUT_FILE="trivy-scan-results.txt"
> "$OUTPUT_FILE"  # Truncate or create the output file

services=("payment-service" "project-service" "user-service" "frontend")
vulnerabilities_found=false

for s in "${services[@]}"; do
  IMAGE="$DOCKER_USERNAME/$DOCKER_REPO_NAME-$s:$TAG"
  echo "Scanning $IMAGE" | tee -a "$OUTPUT_FILE"
  
  # Run Trivy scan and filter only High/Critical vulnerabilities
  TRIVY_OUTPUT=$(trivy image --severity CRITICAL,HIGH --format json "$IMAGE")
  
  # Extract only relevant vulnerabilities and remediation steps
  echo "Vulnerabilities for $IMAGE:" | tee -a "$OUTPUT_FILE"
  echo "$TRIVY_OUTPUT" | jq -r '.Results[] | select(.Vulnerabilities != null) | .Vulnerabilities[] | select(.Severity == "HIGH" or .Severity == "CRITICAL") | "Package: \(.PkgName)\nSeverity: \(.Severity)\nDescription: \(.Description)\nFixed Version: \(.FixedVersion // "Not available")\n---"' | tee -a "$OUTPUT_FILE"
  
  # Check if any vulnerabilities were found
  if echo "$TRIVY_OUTPUT" | jq -e '.Results[] | select(.Vulnerabilities != null) | .Vulnerabilities[] | select(.Severity == "HIGH" or .Severity == "CRITICAL")' > /dev/null; then
    vulnerabilities_found=true
  fi
done

# Notify the user if vulnerabilities are found
if [ "$vulnerabilities_found" = true ]; then
  echo -e "\n🚨 High/Critical vulnerabilities detected in your application images!" | tee -a "$OUTPUT_FILE"
  echo "Please review the vulnerabilities in $OUTPUT_FILE and resolve them." | tee -a "$OUTPUT_FILE"
else
  echo -e "\n✅ No High or Critical vulnerabilities found in your application images." | tee -a "$OUTPUT_FILE"
fi

echo "All images scanned" | tee -a "$OUTPUT_FILE"