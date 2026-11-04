# All-in-One Container: Node.js 20 + MongoDB Server
FROM node:20-bullseye-slim

# Install system utilities & official MongoDB 6.0 Server
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    procps \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | \
       gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main" | \
       tee /etc/apt/sources.list.d/mongodb-org-6.0.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       mongodb-org-server \
    && rm -rf /var/lib/apt/lists/*

# Create directories for MongoDB data, logs, and uploads
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
