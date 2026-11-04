# Multi-stage container using official Node.js image for asset preparation
FROM node:20-slim AS node-base

# All-in-One Production Container: MongoDB 6.0 Base + Node.js 20 LTS
FROM mongo:6.0

# Install Node.js 20 from official NodeSource repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    procps \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create directories for data and uploads
RUN mkdir -p /data/db /var/log/mongodb /app/uploads

WORKDIR /app

# Install production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application source code
COPY . .

# Setup entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Production environment defaults
ENV NODE_ENV=production
ENV PORT=10000
ENV MONGO_URI=mongodb://127.0.0.1:27017/college_cms
ENV JWT_SECRET=campusvoice_prod_jwt_secret_render_2026

EXPOSE 10000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "server.js"]
