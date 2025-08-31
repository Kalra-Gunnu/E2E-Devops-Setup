# Frontend Service - Configurable Endpoints

## Overview
Frontend service with configurable API endpoints and settings. All hardcoded localhost URLs have been replaced with environment variable-based configuration.

## Features
- ✅ Configurable API endpoints
- ✅ Environment-based configuration
- ✅ Docker support with environment variable injection
- ✅ Kubernetes deployment ready
- ✅ Development and production configurations

## Configuration

### Environment Variables
The following environment variables can be configured:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `PROJECT_SERVICE_URL` | Project service API base URL | `http://localhost:3002` |
| `PAYMENT_SERVICE_URL` | Payment service API base URL | `http://localhost:3003` |
| `USER_SERVICE_URL` | User service API base URL | `http://localhost:3001` |
| `RAZORPAY_KEY` | Razorpay public key | `rzp_test_a6CEBoBbltCvzC` |
| `COMPANY_NAME` | Company name for payment | `Dey Education And Research Private Limited` |
| `CURRENCY` | Payment currency | `INR` |

## Development

### Local Development
1. Copy `env.example` to `.env`
2. Update the values in `.env` file
3. Open HTML files in browser

### Using Docker Compose
```bash
cd frontend
docker-compose up --build
```

### Manual Docker Build
```bash
# Build with environment variables
docker build \
  --build-arg PROJECT_SERVICE_URL=http://localhost:3002 \
  --build-arg PAYMENT_SERVICE_URL=http://localhost:3003 \
  --build-arg USER_SERVICE_URL=http://localhost:3001 \
  --build-arg RAZORPAY_KEY=your_key \
  --build-arg COMPANY_NAME="Your Company" \
  --build-arg CURRENCY=INR \
  -t frontend:latest .

# Run container
docker run -p 80:80 frontend:latest
```

## Production Deployment

### Kubernetes
1. Update `k8s/configmap.yaml` with production values
2. Apply the configuration:
   ```bash
   kubectl apply -f k8s/configmap.yaml
   kubectl apply -f k8s/frontend-service.yaml
   ```

### Docker Swarm
```bash
docker stack deploy -c docker-compose.yml frontend
```

## File Structure
```
frontend/
├── template/           # Main HTML templates
├── testingUI/          # Testing interface
├── config.js           # Configuration file (auto-generated)
├── Dockerfile          # Multi-stage Docker build
├── docker-compose.yml  # Local development
├── env.example         # Environment variables template
└── README.md           # This file
```

## How It Works

1. **Configuration Injection**: Environment variables are injected into `config.js` during container startup
2. **Runtime Configuration**: JavaScript files use `window.getApiUrl()` and `window.getConfig()` functions
3. **Service Discovery**: API endpoints are resolved at runtime based on configuration

## Troubleshooting

### Common Issues
1. **Config not loaded**: Ensure `config.js` is included before other scripts
2. **API calls failing**: Check environment variables are set correctly
3. **Docker build issues**: Verify all required build arguments are provided

### Debug Mode
Check browser console for configuration values:
```javascript
console.log(window.APP_CONFIG);
console.log(window.getApiUrl('PROJECT_SERVICE', '/api/projects'));
```
