# Multi-stage production Dockerfile for CampusVoice Backend
FROM node:20-alpine AS base

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application source code
COPY . .

# Set production environment defaults
ENV NODE_ENV=production
ENV PORT=5001

# Expose server port
EXPOSE 5001

# Run as non-root node user
USER node

# Start Node.js API server
CMD ["node", "server.js"]
