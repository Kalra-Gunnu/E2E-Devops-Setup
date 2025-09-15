# ⚙️ Configuration Guide

## 🔧 Customizing DockerHub Username

You can change DockerHub username easily within `config.env` file.

### 📝 Step 1: Edit config.env

```bash
# Open config.env file
nano config.env
```

### 📝 Step 2: Change Username

```bash
# Change this line:
DOCKER_USERNAME=${DOCKER_USERNAME}
```

### 📝 Step 3: Optional - Change Repository Name

```bash
# Change this line:
DOCKER_REPO_NAME=e2e-devops

# To your preferred name:
DOCKER_REPO_NAME=my-project
```

## 🐳 Docker Image Naming Convention

### Current Format:
```
${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-${SERVICE_NAME}:${TAG}
```

### Examples:

#### With Default Values:
- `<user-name>/e2e-devops-payment-service:latest`
- `<user-name>/e2e-devops-project-service:latest`
- `<user-name>/e2e-devops-user-service:latest`

## 🔄 How It Works

### 1. **Configuration Loading**
Scripts automatically load settings from `config.env`:

### 2. **Dynamic Manifest Generation**
`generate-k8s-manifests.sh` creates Kubernetes manifests with your custom image names:

### 3. **Automatic Updates**
All scripts automatically use your configured values.

## 🔍 Verification

### Check Current Configuration
```bash
# View current config
cat config.env

# Check generated manifests
grep "image:" k8s/*-service.yaml
```

### Test Configuration
```bash
# Generate manifests to see image names
./generate-k8s-manifests.sh
```

## ⚠️ Important Notes

1. **File Permissions**: Ensure `config.env` is readable
2. **No Spaces**: Don't use spaces around `=` in config.env
3. **Quotes**: Values don't need quotes unless they contain spaces
4. **Backup**: Keep a backup of your original config.env
5. **Git**: Consider adding config.env to .gitignore for security

## 🆘 Troubleshooting

### Issue: "Configuration not loaded"
```bash
# Check if file exists
ls -la config.env

# Check file permissions
chmod 644 config.env
```

### Issue: "Image not found"
```bash
# Verify image names in manifests
grep "image:" k8s/*-service.yaml

# Check if images were pushed
docker images | grep your-username
```

### Issue: "Permission denied"
```bash
# Make scripts executable
chmod +x *.sh
```

---

**🎉 Now you can easily customize your docker user!**
