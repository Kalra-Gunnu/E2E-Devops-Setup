# ⚙️ Configuration Guide

## 🔧 Customizing DockerHub Username

Aap apna DockerHub username easily change kar sakte hain `config.env` file mein.

### 📝 Step 1: Edit config.env

```bash
# Open config.env file
nano config.env
```

### 📝 Step 2: Change Username

```bash
# Change this line:
DOCKER_USERNAME=prag1402

# To your username:
DOCKER_USERNAME=your-username
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
${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-${SERVICE_NAME}:latest
```

### Examples:

#### With Default Values:
- `prag1402/e2e-devops-payment-service:latest`
- `prag1402/e2e-devops-project-service:latest`
- `prag1402/e2e-devops-user-service:latest`

#### With Custom Username (e.g., `john_doe`):
- `john_doe/e2e-devops-payment-service:latest`
- `john_doe/e2e-devops-project-service:latest`
- `john_doe/e2e-devops-user-service:latest`

#### With Custom Repo Name (e.g., `my-app`):
- `prag1402/my-app-payment-service:latest`
- `prag1402/my-app-project-service:latest`
- `prag1402/my-app-user-service:latest`

## 🔄 How It Works

### 1. **Configuration Loading**
Scripts automatically load settings from `config.env`:

```bash
# Load configuration from config.env file
if [ -f "config.env" ]; then
    source config.env
    echo "✅ Configuration loaded from config.env"
else
    echo "⚠️  config.env not found, using default values"
    DOCKER_USERNAME="prag1402"
    DOCKER_REPO_NAME="e2e-devops"
fi
```

### 2. **Dynamic Manifest Generation**
`generate-k8s-manifests.sh` creates Kubernetes manifests with your custom image names:

```bash
# Generates manifests like:
image: ${DOCKER_USERNAME}/${DOCKER_REPO_NAME}-payment-service:latest
```

### 3. **Automatic Updates**
All scripts automatically use your configured values.

## 📋 Complete Configuration Options

### Docker Configuration
```bash
DOCKER_USERNAME=your-username          # Your DockerHub username
DOCKER_REPO_NAME=your-repo-name       # Repository name prefix
```

### Application Configuration
```bash
NODE_ENV=production                   # Node.js environment
MONGODB_URI=mongodb://...             # MongoDB connection string
REDIS_URL=redis://...                 # Redis connection string
AWS_REGION=us-east-1                  # AWS region
AWS_S3_BUCKET=your-bucket            # S3 bucket name
```

### API Keys
```bash
RAZORPAY_KEY_ID=your-key-id          # Razorpay API key
RAZORPAY_KEY_SECRET=your-secret      # Razorpay secret
AWS_ACCESS_KEY_ID=your-access-key    # AWS access key
AWS_SECRET_ACCESS_KEY=your-secret    # AWS secret key
```

## 🚀 Usage Examples

### Example 1: Change Username Only
```bash
# config.env
DOCKER_USERNAME=john_doe
DOCKER_REPO_NAME=e2e-devops

# Results in:
# john_doe/e2e-devops-payment-service:latest
# john_doe/e2e-devops-project-service:latest
# john_doe/e2e-devops-user-service:latest
```

### Example 2: Change Both Username and Repo
```bash
# config.env
DOCKER_USERNAME=john_doe
DOCKER_REPO_NAME=my-awesome-app

# Results in:
# john_doe/my-awesome-app-payment-service:latest
# john_doe/my-awesome-app-project-service:latest
# john_doe/my-awesome-app-user-service:latest
```

### Example 3: Use Organization Account
```bash
# config.env
DOCKER_USERNAME=my-company
DOCKER_REPO_NAME=production-apps

# Results in:
# my-company/production-apps-payment-service:latest
# my-company/production-apps-project-service:latest
# my-company/production-apps-user-service:latest
```

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

**🎉 Ab aap apna DockerHub username easily customize kar sakte hain!**
