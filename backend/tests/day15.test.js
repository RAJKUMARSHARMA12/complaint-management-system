const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');
const TEST_PORT = 5098;
let server;

const jsonRequest = (method, path, body = null, token = null) => {
  return new Promise((resolve, reject) => {
    const dataString = body ? JSON.stringify(body) : '';
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
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
          resolve({ status: res.statusCode, body: parsed });
        });
      }
    );

    req.on('error', reject);
    if (body) req.write(dataString);
    req.end();
  });
};

const runDay15Tests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 15: Executive Dashboard & Analytics Tests');
  console.log('=============================================\n');

  let passed = 0;
  let failed = 0;

  const assert = (condition, testName, details = '') => {
    if (condition) {
      console.log(`  ✅ PASS: ${testName}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${testName} ${details ? `(${details})` : ''}`);
      failed++;
    }
  };

  try {
    server = app.listen(TEST_PORT);
    await new Promise((r) => setTimeout(r, 500));

    // 1. Authenticate Student and Admin
    const studentLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'aarav.mehta@college.edu',
      password: 'StudentPassword@123'
    });
    assert(studentLogin.status === 200, 'Student logs in successfully');
    const studentToken = studentLogin.body.data.token;

    const adminLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'admin@college.edu',
      password: 'AdminPassword@123'
    });
    assert(adminLogin.status === 200, 'Admin logs in successfully');
    const adminToken = adminLogin.body.data.token;

    // 2. Security / RBAC Checks: Students are blocked from dashboard analytics
    const studentStatsCheck = await jsonRequest('GET', '/api/dashboard/stats', null, studentToken);
    assert(studentStatsCheck.status === 403, 'Student blocked from GET /api/dashboard/stats (403 Forbidden)');

    const unauthCheck = await jsonRequest('GET', '/api/dashboard/stats', null, null);
    assert(unauthCheck.status === 401, 'Unauthenticated user blocked from dashboard (401 Unauthorized)');

    // 3. GET /api/dashboard/stats (Admin)
    const statsRes = await jsonRequest('GET', '/api/dashboard/stats', null, adminToken);
    assert(statsRes.status === 200, 'Admin can access GET /api/dashboard/stats');
    assert(statsRes.body && statsRes.body.success === true, 'Stats response indicates success');
    const stats = statsRes.body.data;
    assert(
      typeof stats.totalComplaints === 'number' &&
      typeof stats.openComplaints === 'number' &&
      typeof stats.resolvedComplaints === 'number' &&
      typeof stats.closedComplaints === 'number' &&
      typeof stats.escalatedComplaints === 'number',
      'Stats payload contains all required KPI fields (total, open, resolved, closed, escalated)'
    );
    assert(
      stats.totalComplaints >= stats.openComplaints + stats.resolvedComplaints + stats.closedComplaints,
      'Total complaints is consistent with status partitions'
    );

    // 4. GET /api/dashboard/by-category (Admin)
    const categoryRes = await jsonRequest('GET', '/api/dashboard/by-category', null, adminToken);
    assert(categoryRes.status === 200, 'Admin can access GET /api/dashboard/by-category');
    assert(Array.isArray(categoryRes.body.data), 'by-category returns an array');
    if (categoryRes.body.data.length > 0) {
      const item = categoryRes.body.data[0];
      assert(
        typeof item.category === 'string' && typeof item.count === 'number',
        'Category distribution items have valid category name and count'
      );
    }

    // 5. GET /api/dashboard/by-status (Admin)
    const statusRes = await jsonRequest('GET', '/api/dashboard/by-status', null, adminToken);
    assert(statusRes.status === 200, 'Admin can access GET /api/dashboard/by-status');
    assert(Array.isArray(statusRes.body.data), 'by-status returns an array');
    const statusMap = {};
    statusRes.body.data.forEach((s) => {
      statusMap[s.status] = s.count;
    });
    const expectedStatuses = ['Submitted', 'Assigned', 'In Progress', 'Resolved', 'Closed'];
    const hasAllStatuses = expectedStatuses.every((st) => typeof statusMap[st] === 'number');
    assert(hasAllStatuses, 'by-status contains entries for all 5 lifecycle statuses', JSON.stringify(statusMap));

    // 6. GET /api/dashboard/monthly-trend (Admin)
    const trendRes = await jsonRequest('GET', '/api/dashboard/monthly-trend', null, adminToken);
    assert(trendRes.status === 200, 'Admin can access GET /api/dashboard/monthly-trend');
    assert(Array.isArray(trendRes.body.data), 'monthly-trend returns an array');
    if (trendRes.body.data.length > 0) {
      const firstMonth = trendRes.body.data[0];
      assert(
        typeof firstMonth.month === 'string' && typeof firstMonth.count === 'number',
        'Monthly trend entries contain month label and numeric count'
      );
    }

    // 7. GET /api/dashboard/resolution-time (Admin)
    const mttrRes = await jsonRequest('GET', '/api/dashboard/resolution-time', null, adminToken);
    assert(mttrRes.status === 200, 'Admin can access GET /api/dashboard/resolution-time');
    assert(Array.isArray(mttrRes.body.data), 'resolution-time returns an array');
    const hasOverall = mttrRes.body.data.some((item) => item.category === 'Overall Average');
    assert(hasOverall, 'resolution-time includes "Overall Average" metric');

  } catch (error) {
    console.error('Fatal test error:', error);
    failed++;
  } finally {
    if (server) {
      await new Promise((r) => server.close(r));
    }
    if (mongoose.connection && mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
    }
    console.log(`\nDay 15 Test Summary: Passed: ${passed}, Failed: ${failed}`);
    process.exit(failed > 0 ? 1 : 0);
  }
};

runDay15Tests();
