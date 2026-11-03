const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');
const Category = require('../models/Category');
const Complaint = require('../models/Complaint');
const User = require('../models/User');

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

const runDay12Tests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 12: Admin Master Console & Delegation Tests');
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

    // 2. Fetch Users filtered by role=authority
    const authorityUsersRes = await jsonRequest('GET', '/api/users?role=authority', null, adminToken);
    assert(authorityUsersRes.status === 200, 'Admin can fetch authority staff via GET /api/users?role=authority');
    assert(
      Array.isArray(authorityUsersRes.body.data.users) && authorityUsersRes.body.data.users.length > 0,
      'Returns list of authority users'
    );
    const authorityUser = authorityUsersRes.body.data.users[0];

    // 3. Fetch Master Complaints as Admin
    const allComplaintsRes = await jsonRequest('GET', '/api/complaints', null, adminToken);
    assert(allComplaintsRes.status === 200, 'Admin can fetch master complaint list via GET /api/complaints');
    assert(
      Array.isArray(allComplaintsRes.body.data.complaints),
      'Returns complaints array'
    );

    // 4. Test Search filter
    const searchRes = await jsonRequest('GET', '/api/complaints?search=Block', null, adminToken);
    assert(searchRes.status === 200, 'Admin can query complaints with search filter');

    // 5. Create a test complaint to assign
    const studentLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'aarav.mehta@college.edu',
      password: 'StudentPassword@123'
    });
    const studentToken = studentLogin.body.data.token;

    const cat = await Category.findOne({ name: 'Hostel Maintenance' });
    const newComplaint = await Complaint.create({
      complaintId: `CMP-${Date.now().toString().slice(-4)}`,
      title: 'Admin Delegation Test Issue',
      description: 'Testing administrative delegation to department authority.',
      category: cat._id,
      location: 'Block C 101',
      priority: 'High',
      status: 'Submitted',
      createdBy: studentLogin.body.data.user.id
    });

    // 6. Admin delegates/assigns to authority
    const assignRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${newComplaint._id}/assign`,
      {
        authorityId: authorityUser.id,
        remark: 'Assigned by principal admin office'
      },
      adminToken
    );

    assert(assignRes.status === 200, 'Admin can assign complaint to authority');
    assert(assignRes.body.data.status === 'Assigned', 'Complaint status transitions to Assigned');

    // Clean up test complaint
    await Complaint.findByIdAndDelete(newComplaint._id);

  } catch (err) {
    console.error('Fatal error during Day 12 tests:', err);
    failed++;
  } finally {
    if (server) {
      server.close();
    }
    console.log(`\nDay 12 Tests Summary: Passed: ${passed}, Failed: ${failed}`);
    process.exit(failed > 0 ? 1 : 0);
  }
};

runDay12Tests();
