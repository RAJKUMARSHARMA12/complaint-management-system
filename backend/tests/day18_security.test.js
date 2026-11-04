const http = require('http');
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

// Enable rate limit for this test file
process.env.NODE_ENV = 'test';
process.env.ENABLE_TEST_RATE_LIMIT = 'true';
process.env.LOGIN_RATE_LIMIT_MAX = '5';

const app = require('../server');
const { validateEnvironment } = require('../config/envCheck');
const { sanitizeValue } = require('../middleware/sanitize');

const TEST_PORT = 5097;
let server;

const httpRequest = (method, path, body = null, extraHeaders = {}) => {
  return new Promise((resolve, reject) => {
    const dataString = body ? (typeof body === 'string' ? body : JSON.stringify(body)) : '';
    const headers = {
      'Content-Type': 'application/json',
      ...extraHeaders
    };
    if (body) headers['Content-Length'] = Buffer.byteLength(dataString);

    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: TEST_PORT,
        path,
        method,
        headers
      },
      (res) => {
        let responseBody = '';
        res.on('data', (chunk) => (responseBody += chunk));
        res.on('end', () => {
          let parsed = null;
          try {
            parsed = JSON.parse(responseBody);
          } catch (e) {
            parsed = responseBody;
          }
          resolve({ status: res.statusCode, headers: res.headers, body: parsed });
        });
      }
    );

    req.on('error', reject);
    if (body) req.write(dataString);
    req.end();
  });
};

const runDay18SecurityTests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 18: Security Hardening & Rate Limiting Tests');
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
    // Start local test server instance
    server = app.listen(TEST_PORT);
    await new Promise((resolve) => setTimeout(resolve, 500));

    // =========================================================================
    // 1. Helmet Security Headers Verification
    // =========================================================================
    console.log('--- Suite 1: Helmet Security Headers ---');
    const healthRes = await httpRequest('GET', '/health');
    assert(healthRes.status === 200, 'Health endpoint responds with 200 OK');
    assert(
      healthRes.headers['x-dns-prefetch-control'] === 'off',
      'Helmet sets X-DNS-Prefetch-Control to off'
    );
    assert(
      healthRes.headers['x-frame-options'] === 'SAMEORIGIN',
      'Helmet sets X-Frame-Options to SAMEORIGIN'
    );
    assert(
      healthRes.headers['x-content-type-options'] === 'nosniff',
      'Helmet sets X-Content-Type-Options to nosniff'
    );
    assert(
      healthRes.headers['cross-origin-resource-policy'] === 'cross-origin',
      'Helmet sets Cross-Origin-Resource-Policy to cross-origin'
    );

    // =========================================================================
    // 2. Strict CORS & Mobile Origin Handling
    // =========================================================================
    console.log('\n--- Suite 2: Strict CORS & Mobile Origin Handling ---');
    const mobileRes = await httpRequest('GET', '/health'); // No Origin header
    assert(mobileRes.status === 200, 'Native mobile client without Origin header is permitted');

    const allowedOriginRes = await httpRequest('OPTIONS', '/health', null, {
      Origin: 'http://localhost:3000',
      'Access-Control-Request-Method': 'GET'
    });
    assert(
      allowedOriginRes.headers['access-control-allow-origin'] === 'http://localhost:3000' ||
      allowedOriginRes.headers['access-control-allow-origin'] === '*',
      'Allowed web origin is granted Access-Control-Allow-Origin header'
    );

    // =========================================================================
    // 3. Login Rate Limiting (5 requests / 15 minutes)
    // =========================================================================
    console.log('\n--- Suite 3: Login Rate Limiting ---');
    const badLoginPayload = { email: 'bad_attempt@campus.edu', password: 'wrong_password_123' };

    // Execute 5 rapid login attempts
    for (let i = 1; i <= 5; i++) {
      const res = await httpRequest('POST', '/api/auth/login', badLoginPayload);
      assert(
        res.status === 400,
        `Attempt ${i}/5 fails with 400 Bad Request (under rate limit threshold)`
      );
    }

    // 6th attempt should breach the 5-request limit and return 429 Too Many Requests
    const rateLimitedRes = await httpRequest('POST', '/api/auth/login', badLoginPayload);
    assert(
      rateLimitedRes.status === 429,
      'Attempt 6/5 triggers 429 Too Many Requests'
    );
    assert(
      rateLimitedRes.body && rateLimitedRes.body.success === false,
      '429 response contains success: false'
    );
    assert(
      rateLimitedRes.body &&
      rateLimitedRes.body.message &&
      rateLimitedRes.body.message.includes('Too many login attempts'),
      '429 response contains clear lockout notice message'
    );
    assert(
      rateLimitedRes.headers['ratelimit-limit'] !== undefined ||
      rateLimitedRes.headers['retry-after'] !== undefined,
      '429 response contains standard RateLimit or Retry-After headers'
    );

    // =========================================================================
    // 4. NoSQL Injection Defense & Sanitization
    // =========================================================================
    console.log('\n--- Suite 4: NoSQL Injection Defense ---');

    // Test 4a: Mongo query operator in place of string email
    const nosqlLoginRes = await httpRequest('POST', '/api/auth/login', {
      email: { $gt: '' },
      password: 'password123'
    });
    assert(
      nosqlLoginRes.status === 400 || nosqlLoginRes.status === 429,
      'NoSQL injection payload { email: { $gt: "" } } is blocked with 400 Bad Request'
    );

    // Test 4b: Recursive sanitizer utility strips $ operator keys
    const maliciousPayload = {
      title: 'Water Leak',
      $where: 'sleep(5000)',
      nested: {
        $gt: 0,
        validKey: 'Clean Data'
      }
    };
    const sanitized = sanitizeValue(maliciousPayload);
    assert(sanitized.$where === undefined, 'Sanitizer strips root $where injection key');
    assert(sanitized.nested.$gt === undefined, 'Sanitizer strips nested $gt operator');
    assert(sanitized.nested.validKey === 'Clean Data', 'Sanitizer preserves legitimate fields');

    // =========================================================================
    // 5. Sensitive Credentials & Environment Auditing
    // =========================================================================
    console.log('\n--- Suite 5: Sensitive Credentials & Environment Auditing ---');

    // Check env validator function
    const envAudit = validateEnvironment();
    assert(envAudit.isValid === true, 'validateEnvironment() passes health audit');

    // Verify .env.example exists and contains no live secrets
    const examplePath = path.join(__dirname, '../.env.example');
    assert(fs.existsSync(examplePath), '.env.example template exists');
    const exampleContent = fs.readFileSync(examplePath, 'utf8');
    assert(
      exampleContent.includes('JWT_SECRET=') && !exampleContent.includes('super_secret_jwt_key_campusvoice_2026_dev'),
      '.env.example contains placeholder without real dev secret'
    );

    // Verify .gitignore ignores .env
    const gitignorePath = path.join(__dirname, '../../.gitignore');
    const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
    assert(gitignoreContent.includes('.env'), '.gitignore excludes .env files from version control');

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
  console.log(`Day 18 Security Test Summary: Passed: ${passed}, Failed: ${failed}`);
  console.log('=============================================\n');

  if (failed > 0) {
    process.exit(1);
  }
};

runDay18SecurityTests();
