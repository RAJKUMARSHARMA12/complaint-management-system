const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');
const Category = require('../models/Category');
const User = require('../models/User');

const TEST_PORT = 5097;
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

const runDay13Tests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 13: Category & User Governance Tests');
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

    // 1. Login as Admin
    const adminLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'admin@college.edu',
      password: 'AdminPassword@123'
    });
    assert(adminLogin.status === 200, 'Admin can login successfully');
    const adminToken = adminLogin.body.data.token;

    // 2. Admin can fetch all categories including inactive ones
    const allCategoriesRes = await jsonRequest('GET', '/api/categories/all', null, adminToken);
    assert(allCategoriesRes.status === 200, 'Admin can fetch all categories via GET /api/categories/all');
    assert(Array.isArray(allCategoriesRes.body.data), 'Returns categories array');

    // 3. Admin can create a new category (e.g. Sports Complex)
    const testCatName = `Sports Complex ${Date.now()}`;
    const createCatRes = await jsonRequest('POST', '/api/categories', {
      name: testCatName,
      description: 'Court and stadium maintenance',
      slaDays: 4
    }, adminToken);
    assert(createCatRes.status === 201, 'Admin can create a new category via POST /api/categories');
    assert(createCatRes.body.data.name === testCatName, 'Created category has matching name');
    const createdCatId = createCatRes.body.data.id;

    // 4. Admin can toggle category active flag
    const toggleCatRes = await jsonRequest('PATCH', `/api/categories/${createdCatId}/status`, {
      isActive: false
    }, adminToken);
    assert(toggleCatRes.status === 200, 'Admin can toggle category active flag via PATCH /api/categories/:id/status');
    assert(toggleCatRes.body.data.isActive === false, 'Category isActive updated to false');

    // 5. Admin can fetch user list by role (authorities and students)
    const authUsersRes = await jsonRequest('GET', '/api/users?role=authority', null, adminToken);
    assert(authUsersRes.status === 200, 'Admin can query users with role=authority');
    assert(Array.isArray(authUsersRes.body.data.users), 'Returns authority users array');

    const studentUsersRes = await jsonRequest('GET', '/api/users?role=student', null, adminToken);
    assert(studentUsersRes.status === 200, 'Admin can query users with role=student');
    assert(Array.isArray(studentUsersRes.body.data.users), 'Returns student users array');

    // 6. Admin can create new Authority user account
    const testAuthEmail = `sports.coach.${Date.now()}@college.edu`;
    const createAuthRes = await jsonRequest('POST', '/api/users/authority', {
      name: 'Coach David',
      email: testAuthEmail,
      password: 'CoachPassword@123',
      department: 'Sports Complex',
      phone: '9876543210'
    }, adminToken);
    assert(createAuthRes.status === 201, 'Admin can create authority user via POST /api/users/authority');
    assert(createAuthRes.body.data.role === 'authority', 'Created user has authority role');
    const createdUserId = createAuthRes.body.data.id;

    // 7. Admin can toggle user active status
    const toggleUserRes = await jsonRequest('PATCH', `/api/users/${createdUserId}/status`, {
      isActive: false
    }, adminToken);
    assert(toggleUserRes.status === 200, 'Admin can toggle user active status via PATCH /api/users/:id/status');
    assert(toggleUserRes.body.data.isActive === false, 'User isActive updated to false');

    // Cleanup created test documents
    await Category.findByIdAndDelete(createdCatId);
    await User.findByIdAndDelete(createdUserId);

  } catch (err) {
    console.error('Test execution error:', err);
    failed++;
  } finally {
    if (server) {
      server.close();
    }
    console.log(`\nDay 13 Tests Summary: Passed: ${passed}, Failed: ${failed}\n`);
    process.exit(failed > 0 ? 1 : 0);
  }
};

runDay13Tests();
