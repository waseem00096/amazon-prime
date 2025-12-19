FROM node:alpine

# Install Nginx
RUN apk add --no-cache  nginx

# Create and set the working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json /app/
RUN npm install

# Copy the rest of your code
COPY . /app/

# Copy Nginx config to the correct location
COPY nginx/default.conf  /etc/nginx/http.d/default.conf

# Copy the startup script and make it executable
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose port 80 (Nginx) instead of 3000
EXPOSE 80

# Use the script to start both services
CMD ["/app/start.sh"]
