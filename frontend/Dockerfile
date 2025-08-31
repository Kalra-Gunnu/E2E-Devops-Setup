# Multi-stage build to handle environment variable substitution
FROM node:18-alpine AS builder

# Install envsubst
RUN apk add --no-cache gettext

# Set working directory
WORKDIR /app

# Copy template files
COPY template/ ./template/
COPY testingUI/ ./testingUI/

# Create a script to substitute environment variables
RUN echo '#!/bin/sh\n\
envsubst < template/config.js > template/config.js.tmp && mv template/config.js.tmp template/config.js\n\
echo "Environment variables substituted successfully"\n\
' > /app/substitute-env.sh && chmod +x /app/substitute-env.sh

# Final stage with nginx
FROM nginx:alpine

# Install envsubst in the final image
RUN apk add --no-cache gettext

# Copy the substitution script
COPY --from=builder /app/substitute-env.sh /substitute-env.sh

# Copy template files
COPY --from=builder /app/template/ /usr/share/nginx/html/
COPY --from=builder /app/testingUI/ /usr/share/nginx/html/testingUI/

# Create a startup script
RUN echo '#!/bin/sh\n\
/substitute-env.sh\n\
nginx -g "daemon off;"\n\
' > /startup.sh && chmod +x /startup.sh

EXPOSE 80

CMD ["/startup.sh"]