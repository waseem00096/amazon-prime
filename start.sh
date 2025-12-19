#!/bin/sh

# Start the Node.js application in the background
npm start &

# Start Nginx in the foreground
nginx -g "daemon off;"
