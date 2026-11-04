const fs = require('fs');
const path = require('path');
const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

process.env.NODE_ENV = 'test';
dotenv.config();

const app = require('../server');
const { verifyCloudConnection } = require('../scripts/verifyCloud');

const TEST_PORT = 5096;
let server;

const httpRequest = (path) => {
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: TEST_PORT,
        path,
        method: 'GET'
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, body: JSON.parse(body) });
          } catch {
            resolve({ status: res.statusCode, body });
          }
        });
      }
    );
    req.on('error', reject);
    req.end();
  });
};

const runDay19CloudTests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 19: Cloud Deployment & Atlas Verification Tests');
  console.log('=============================================\n');

  let passed = 0;
  let failed = 0;

  const assert = (condition, description) => {
    if (condition) {
      console.log(`  ✅ PASS: ${description}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${description}`);
      failed++;
    }
  };

  try {
    server = app.listen(TEST_PORT);
    await new Promise((resolve) => setTimeout(resolve, 300));

    // 1. Render Blueprint Specification Audit
    console.log('--- Suite 1: Render.com Cloud Specification ---');
    const renderYamlPath = path.join(__dirname, '../../render.yaml');
    assert(fs.existsSync(renderYamlPath), 'render.yaml blueprint exists in project root');

    const renderContent = fs.readFileSync(renderYamlPath, 'utf8');
    assert(renderContent.includes('name: campusvoice-api'), 'Render service name is campusvoice-api');
    assert(renderContent.includes('startCommand: node server.js'), 'Start command runs server.js');
    assert(renderContent.includes('healthCheckPath: /health'), 'Health check path set to /health');
    assert(renderContent.includes('key: MONGO_URI'), 'MONGO_URI declared in blueprint');
    assert(renderContent.includes('key: JWT_SECRET'), 'JWT_SECRET declared in blueprint');
    assert(renderContent.includes('key: ALLOWED_ORIGINS'), 'ALLOWED_ORIGINS declared in blueprint');

    // 2. Production Dockerfile Audit
    console.log('\n--- Suite 2: Production Containerization ---');
    const dockerfilePath = path.join(__dirname, '../Dockerfile');
    assert(fs.existsSync(dockerfilePath), 'backend/Dockerfile exists');

    const dockerContent = fs.readFileSync(dockerfilePath, 'utf8');
    assert(dockerContent.includes('FROM node:'), 'Dockerfile uses official Node.js base image');
    assert(dockerContent.includes('CMD ["node", "server.js"]'), 'Dockerfile starts server with node server.js');
    assert(dockerContent.includes('EXPOSE'), 'Dockerfile exposes service port');

    // 3. Health & Uptime Endpoints
    console.log('\n--- Suite 3: Cloud Health Endpoints ---');
    const rootHealth = await httpRequest('/health');
    assert(rootHealth.status === 200, 'GET /health responds with 200 OK');
    assert(rootHealth.body.status === 'ok', 'Root health status is "ok"');
    assert(typeof rootHealth.body.uptime === 'number', 'Root health returns numeric uptime');

    const apiHealth = await httpRequest('/api/health');
    assert(apiHealth.status === 200, 'GET /api/health responds with 200 OK');
    assert(apiHealth.body.service === 'CampusVoice API', 'API health service is "CampusVoice API"');

    // 4. Cloud Database / Atlas Connectivity Verification
    console.log('\n--- Suite 4: Database Connectivity Verification ---');
    const dbReport = await verifyCloudConnection();
    assert(dbReport.success === true, 'Cloud database connection verifies successfully');
    assert(typeof dbReport.latencyMs === 'number' && dbReport.latencyMs < 1000, 'Database ping latency is responsive');
    assert(Array.isArray(dbReport.collections), 'Collections array retrieved');

    // 5. Database Seed Script Verification
    console.log('\n--- Suite 5: Cloud Seeder Verification ---');
    const seedPath = path.join(__dirname, '../seed/seed.js');
    assert(fs.existsSync(seedPath), 'backend/seed/seed.js exists');
    const seedContent = fs.readFileSync(seedPath, 'utf8');
    assert(seedContent.includes('admin@college.edu'), 'Seed script includes Dean Super Admin');
    assert(seedContent.includes('warden.hostel@college.edu'), 'Seed script includes Hostel Warden');
    assert(seedContent.includes('Hostel Maintenance'), 'Seed script includes default categories');

  } catch (err) {
    console.error(`[Test Execution Error] ${err.message}`);
    failed++;
  } finally {
    if (server) {
      server.close();
    }
    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
  }

  console.log('\n---------------------------------------------');
  console.log(`Day 19 Cloud Test Summary: Passed: ${passed}, Failed: ${failed}`);
  console.log('=============================================\n');

  process.exit(failed > 0 ? 1 : 0);
};

runDay19CloudTests();
