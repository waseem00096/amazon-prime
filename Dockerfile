# 1. Use a stable LTS version (Node 20) instead of the latest/experimental alpine
# This fixes many underlying vulnerabilities in the node runtime layers.
FROM node:20-alpine

# 2. Update the OS and install Nginx
# 'apk upgrade' is crucial—it updates existing packages to their latest secure versions.
RUN apk update && \
    apk upgrade && \
    apk add --no-cache nginx

# Create and set the working directory
WORKDIR /app

# 3. Use wildcard to ensure both package files are copied
COPY package*.json ./

# 4. Install dependencies (Run 'npm audit fix' locally before pushing code!)
RUN npm install --only=production
RUN npm audit fix

COPY . .

# Copy Nginx config to the correct location
# Note: In newer Alpine versions, /etc/nginx/http.d/ is standard.
COPY nginx/default.conf /etc/nginx/http.d/default.conf

# Copy the startup script and make it executable
RUN chmod +x /app/start.sh

# Expose port 80 for the Nginx Reverse Proxy
EXPOSE 80

# Use the script to start both services
CMD ["/app/start.sh"]
