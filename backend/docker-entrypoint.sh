#!/bin/sh
set -e

# Ensure production environment variables for all-in-one container
export MONGO_URI="mongodb://127.0.0.1:27017/college_cms"
export PORT="${PORT:-10000}"
export NODE_ENV="production"
export JWT_SECRET="${JWT_SECRET:-campusvoice_prod_jwt_secret_render_2026}"
export ALLOWED_ORIGINS="${ALLOWED_ORIGINS:-*}"

echo "========================================="
echo "🚀 CampusVoice All-in-One Container Boot"
echo "========================================="
echo "  Port:        $PORT"
echo "  Environment: $NODE_ENV"
echo "  Database:    $MONGO_URI"
echo "-----------------------------------------"

# 1. Start MongoDB daemon in background
echo "[1/3] Starting internal MongoDB daemon on 127.0.0.1:27017..."
mkdir -p /data/db /var/log/mongodb
mongod --fork --logpath /var/log/mongodb/mongod.log --dbpath /data/db --bind_ip 127.0.0.1

# 2. Wait until mongod is accepting connections
echo "[2/3] Waiting for MongoDB socket to become ready..."
for i in $(seq 1 30); do
  if node -e "const mongoose = require('mongoose'); mongoose.connect('mongodb://127.0.0.1:27017/college_cms', { serverSelectionTimeoutMS: 1000 }).then(() => { mongoose.disconnect(); process.exit(0); }).catch(() => process.exit(1));" > /dev/null 2>&1; then
    echo "  ✅ MongoDB is ready and accepting connections."
    break
  fi
  sleep 1
done

# 3. Seed default roles, categories & users if empty
echo "[3/3] Checking and seeding database records..."
node seed/seed.js || echo "  ⚠️ Seeding completed or already initialized."

echo "-----------------------------------------"
echo "🎉 Starting CampusVoice Node.js Server on port $PORT..."
echo "-----------------------------------------"

if [ "$#" -eq 0 ]; then
  exec node server.js
else
  exec "$@"
fi
