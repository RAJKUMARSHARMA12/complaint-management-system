const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');

const TEST_PORT = 5099;
let server;

const request = (method, path, body = null, headers = {}) => {
  return new Promise((resolve, reject) => {
    const dataString = body ? JSON.stringify(body) : '';
    const reqHeaders = {
      'Content-Type': 'application/json',
      ...headers
    };
    if (body) {
      reqHeaders['Content-Length'] = Buffer.byteLength(dataString);
    }

    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: TEST_PORT,
        path,
        method,
        headers: reqHeaders
      },
      (res) => {
        let responseBody = '';
        res.on('data', (chunk) => {
          responseBody += chunk;
        });
        res.on('end', () => {
          let parsed = null;
          try {
            parsed = JSON.parse(responseBody);
          } catch (e) {
            parsed = responseBody;
          }
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: parsed
          });
        });
      }
    );

    req.on('error', (err) => reject(err));
    if (body) {
      req.write(dataString);
    }
    req.end();
  });
};

const runTests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting CampusVoice Authentication Test Suite');
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
    // Start dedicated test server
    server = app.listen(TEST_PORT);
    await new Promise((resolve) => setTimeout(resolve, 500));

    // Test 1: Health check
    const healthRes = await request('GET', '/health');
    assert(healthRes.status === 200 && healthRes.body.status === 'ok', 'GET /health returns 200 OK');

    // Test 2: Valid Student Registration
    const testEmail = `newstudent_${Date.now()}@college.edu`;
    const regRes = await request('POST', '/api/auth/register', {
      name: 'Test Student',
      email: testEmail,
      password: 'StudentPassword@123',
      phone: '9876543299',
      studentId: 'CS2026999',
      department: 'Computer Science'
    });
    assert(
      regRes.status === 201 &&
        regRes.body.success === true &&
        regRes.body.data.token &&
        regRes.body.data.user.role === 'student',
      'POST /api/auth/register creates student and returns signed token'
    );

    const studentToken = regRes.body.data?.token;

    // Test 3: Duplicate Registration fails (409 Conflict)
    const dupRes = await request('POST', '/api/auth/register', {
      name: 'Duplicate Student',
      email: testEmail,
      password: 'StudentPassword@123'
    });
    assert(dupRes.status === 409 && dupRes.body.success === false, 'POST /api/auth/register duplicate email returns 409 Conflict');

    // Test 4: Registration validation failure (short password)
    const valRes = await request('POST', '/api/auth/register', {
      name: 'Bad',
      email: 'bademail',
      password: '123'
    });
    assert(valRes.status === 400 && valRes.body.success === false, 'POST /api/auth/register invalid inputs return 400 Bad Request');

    // Test 5: Valid Admin Login
    const adminLoginRes = await request('POST', '/api/auth/login', {
      email: 'admin@college.edu',
      password: 'AdminPassword@123'
    });
    assert(
      adminLoginRes.status === 200 &&
        adminLoginRes.body.success === true &&
        adminLoginRes.body.data.token &&
        adminLoginRes.body.data.user.role === 'admin',
      'POST /api/auth/login with valid admin credentials returns 200 OK and admin role'
    );

    const adminToken = adminLoginRes.body.data?.token;

    // Test 6: Invalid Login Password
    const badPassRes = await request('POST', '/api/auth/login', {
      email: 'admin@college.edu',
      password: 'WrongPassword@123'
    });
    assert(badPassRes.status === 400 && badPassRes.body.success === false, 'POST /api/auth/login with wrong password returns 400');

    // Test 7: Non-existent User Login
    const noUserRes = await request('POST', '/api/auth/login', {
      email: 'nonexistent@college.edu',
      password: 'Password@123'
    });
    assert(noUserRes.status === 400 && noUserRes.body.success === false, 'POST /api/auth/login for non-existent user returns 400');

    // Test 8: Protected GET /api/auth/me without token returns 401
    const noTokenRes = await request('GET', '/api/auth/me');
    assert(noTokenRes.status === 401 && noTokenRes.body.success === false, 'GET /api/auth/me without Bearer token returns 401 Unauthorized');

    // Test 9: Protected GET /api/auth/me with valid token returns current user
    const meRes = await request('GET', '/api/auth/me', null, {
      Authorization: `Bearer ${studentToken}`
    });
    assert(
      meRes.status === 200 &&
        meRes.body.success === true &&
        meRes.body.data.email === testEmail &&
        meRes.body.data.role === 'student',
      'GET /api/auth/me with Bearer token decodes user profile correctly'
    );

    // Test 10: Change password with valid current password
    const changePassRes = await request(
      'PUT',
      '/api/auth/change-password',
      {
        currentPassword: 'StudentPassword@123',
        newPassword: 'NewUpdatedPassword@123'
      },
      { Authorization: `Bearer ${studentToken}` }
    );
    assert(changePassRes.status === 200 && changePassRes.body.success === true, 'PUT /api/auth/change-password successfully updates password');

    // Test 11: Login with new updated password
    const newLoginRes = await request('POST', '/api/auth/login', {
      email: testEmail,
      password: 'NewUpdatedPassword@123'
    });
    assert(newLoginRes.status === 200 && newLoginRes.body.success === true, 'POST /api/auth/login succeeds with updated password');

    // Test 12: Deactivated User Login check (403 Forbidden)
    const User = require('../models/User');
    const deactivatedUser = await User.create({
      name: 'Deactivated Person',
      email: `deactivated_${Date.now()}@college.edu`,
      password: 'SecretPassword@123',
      role: 'student',
      isActive: false
    });

    const deactLoginRes = await request('POST', '/api/auth/login', {
      email: deactivatedUser.email,
      password: 'SecretPassword@123'
    });
    assert(
      deactLoginRes.status === 403 && deactLoginRes.body.success === false,
      'POST /api/auth/login for deactivated user returns 403 Forbidden'
    );

    // Test 13: RBAC Middleware verification
    const { authorize } = require('../middleware/role');
    const mockReqAdmin = { user: { role: 'admin' } };
    const mockReqStudent = { user: { role: 'student' } };
    let rbacNextCalled = false;
    let rbacForbiddenStatus = null;
    const mockRes = {
      status: (code) => {
        rbacForbiddenStatus = code;
        return {
          json: () => {}
        };
      }
    };

    authorize('admin')(mockReqAdmin, mockRes, () => {
      rbacNextCalled = true;
    });
    assert(rbacNextCalled === true, 'RBAC middleware allows admin role for admin route');

    authorize('admin')(mockReqStudent, mockRes, () => {});
    assert(rbacForbiddenStatus === 403, 'RBAC middleware denies student role with 403 Forbidden');

    console.log('\n---------------------------------------------');
    console.log(`Results: ${passed} Passed, ${failed} Failed`);
    console.log('=============================================\n');

    server.close();
    await mongoose.connection.close();
    process.exit(failed > 0 ? 1 : 0);
  } catch (err) {
    console.error('Test Runner Error:', err);
    if (server) server.close();
    await mongoose.connection.close();
    process.exit(1);
  }
};

runTests();
