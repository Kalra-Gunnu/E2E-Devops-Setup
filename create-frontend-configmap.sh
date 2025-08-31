#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📁 Creating frontend files ConfigMap...${NC}"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo -e "${GREEN}✅ Temporary directory created: ${TEMP_DIR}${NC}"

# Copy only main frontend files (avoiding problematic filenames)
cp frontend/template/* $TEMP_DIR/

echo -e "${GREEN}✅ Main frontend files copied to temp directory${NC}"

# Create ConfigMap from directory
kubectl create configmap frontend-files --from-file=$TEMP_DIR/ -n e2e-devops --dry-run=client -o yaml > k8s/frontend-configmap.yaml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend ConfigMap YAML created${NC}"
    
    # Apply the ConfigMap
    kubectl apply -f k8s/frontend-configmap.yaml
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Frontend ConfigMap applied successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to apply ConfigMap${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Failed to create ConfigMap YAML${NC}"
fi

# Clean up temp directory
rm -rf $TEMP_DIR
echo -e "${GREEN}✅ Temporary directory cleaned up${NC}"

echo -e "${GREEN}🎉 Frontend ConfigMap setup complete!${NC}"
