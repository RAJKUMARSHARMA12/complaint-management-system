#!/bin/sh
set -e

echo "========================================="
echo "🚀 CampusVoice All-in-One Container Boot"
echo "========================================="

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
node seed/seed.js || echo "  ⚠️ Seeding skipped or completed."

echo "-----------------------------------------"
echo "🎉 Starting CampusVoice Application Process..."
echo "-----------------------------------------"

if [ "$#" -eq 0 ]; then
  exec node server.js
else
  exec "$@"
fi
