const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');
const Category = require('../models/Category');
const Complaint = require('../models/Complaint');
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

const multipartRequest = (method, path, fields, files = [], token = null) => {
  return new Promise((resolve, reject) => {
    const boundary = '----CampusVoiceBoundary' + Date.now();
    let bodyBuffer = Buffer.alloc(0);

    for (const [key, value] of Object.entries(fields)) {
      let fieldHeader = `--${boundary}\r\n`;
      fieldHeader += `Content-Disposition: form-data; name="${key}"\r\n\r\n`;
      fieldHeader += `${value}\r\n`;
      bodyBuffer = Buffer.concat([bodyBuffer, Buffer.from(fieldHeader, 'utf8')]);
    }

    bodyBuffer = Buffer.concat([bodyBuffer, Buffer.from(`--${boundary}--\r\n`, 'utf8')]);

    const headers = {
      'Content-Type': `multipart/form-data; boundary=${boundary}`,
      'Content-Length': bodyBuffer.length
    };
    if (token) headers['Authorization'] = `Bearer ${token}`;

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
    req.write(bodyBuffer);
    req.end();
  });
};

const runDay5Tests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 5: FSM Workflow, Whistleblower Privacy & Remarks Tests');
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

    // 1. Authenticate Actors: Admin, Authority (Warden), Authority (Electrician), Student
    const adminLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'admin@college.edu',
      password: 'AdminPassword@123'
    });
    const adminToken = adminLogin.body.data.token;

    const wardenLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'warden.hostel@college.edu',
      password: 'WardenPassword@123'
    });
    const wardenToken = wardenLogin.body.data.token;
    const wardenId = wardenLogin.body.data.user.id;

    const electricianLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'electrician@college.edu',
      password: 'SparkPassword@123'
    });
    const electricianToken = electricianLogin.body.data.token;
    const electricianId = electricianLogin.body.data.user.id;

    const studentLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'aarav.mehta@college.edu',
      password: 'StudentPassword@123'
    });
    const studentToken = studentLogin.body.data.token;

    // Get categories
    const categoriesRes = await jsonRequest('GET', '/api/categories', null, studentToken);
    const hostelCat = categoriesRes.body.data.find((c) => c.name === 'Hostel Maintenance');
    const sanitationCat = categoriesRes.body.data.find(
      (c) => c.name === 'Sanitation & Campus Cleanliness'
    );

    // ----------------------------------------------------
    // Scenario 1: Whistleblower Masking & Scrubbing Test
    // ----------------------------------------------------
    const anonComplaintRes = await multipartRequest(
      'POST',
      '/api/complaints',
      {
        title: 'Hostel mess hygiene violation reported anonymously',
        description: 'Severe contamination observed in the kitchen food preparation area.',
        category: hostelCat.id,
        location: 'Mess Block C Kitchen',
        priority: 'Urgent',
        isAnonymous: 'true'
      },
      [],
      studentToken
    );

    const anonComplaintId = anonComplaintRes.body.data.id;
    assert(
      anonComplaintRes.status === 201 && anonComplaintRes.body.data.isAnonymous === true,
      'POST /api/complaints lodges anonymous complaint successfully'
    );

    // Student owner views their own complaint -> PII preserved
    const studentViewRes = await jsonRequest(
      'GET',
      `/api/complaints/${anonComplaintId}`,
      null,
      studentToken
    );
    assert(
      studentViewRes.status === 200 &&
        studentViewRes.body.data.createdBy.name === 'Aarav Mehta' &&
        studentViewRes.body.data.createdBy.email === 'aarav.mehta@college.edu',
      'GET /api/complaints/:id allows student owner to see their own identity on anonymous complaint'
    );

    // Authority views anonymous complaint -> PII stripped and scrubbed
    const authorityViewRes = await jsonRequest(
      'GET',
      `/api/complaints/${anonComplaintId}`,
      null,
      wardenToken
    );
    assert(
      authorityViewRes.status === 200 &&
        authorityViewRes.body.data.createdBy.name === 'Anonymous Student' &&
        authorityViewRes.body.data.createdBy.email === null &&
        authorityViewRes.body.data.createdBy.phone === null &&
        authorityViewRes.body.data.createdBy.id === null,
      'GET /api/complaints/:id scrubs student PII for authority on anonymous complaint'
    );

    // Authority views assigned queue -> PII scrubbed in list
    const assignedQueueRes = await jsonRequest('GET', '/api/complaints/assigned', null, wardenToken);
    const foundAnonInQueue = assignedQueueRes.body.data.complaints.find(
      (c) => c.id === anonComplaintId
    );
    assert(
      foundAnonInQueue &&
        foundAnonInQueue.createdBy.name === 'Anonymous Student' &&
        foundAnonInQueue.createdBy.email === null,
      'GET /api/complaints/assigned scrubs student PII in authority queue listing'
    );

    // ----------------------------------------------------
    // Scenario 2: Admin Master Search & Reassignment
    // ----------------------------------------------------
    // Create an unassigned complaint
    const unassignedRes = await multipartRequest(
      'POST',
      '/api/complaints',
      {
        title: 'Broken electrical switch in Computer Lab 3',
        description: 'Exposed wiring near terminal 12 sparking when turned on.',
        category: sanitationCat.id, // sanitation has defaultAuthority: null
        location: 'CS Lab 3, Terminal 12',
        priority: 'High',
        isAnonymous: 'false'
      },
      [],
      studentToken
    );

    const unassignedComplaintId = unassignedRes.body.data.id;
    assert(
      unassignedRes.body.data.status === 'Submitted' && unassignedRes.body.data.assignedTo === null,
      'Created unassigned complaint with status=Submitted'
    );

    // Admin searches console
    const adminSearchRes = await jsonRequest(
      'GET',
      '/api/complaints?search=' + encodeURIComponent('Terminal 12'),
      null,
      adminToken
    );
    assert(
      adminSearchRes.status === 200 &&
        adminSearchRes.body.data.complaints.some((c) => c.id === unassignedComplaintId),
      'GET /api/complaints allows admin multi-parameter search (by location/title)'
    );

    // Admin assigns to Electrician
    const assignRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${unassignedComplaintId}/assign`,
      {
        authorityId: electricianId,
        remark: 'Assigned to senior campus electrician'
      },
      adminToken
    );
    assert(
      assignRes.status === 200 &&
        assignRes.body.success === true &&
        assignRes.body.data.status === 'Assigned' &&
        assignRes.body.data.assignedTo === electricianId &&
        assignRes.body.data.dueDate !== null,
      'PATCH /api/complaints/:id/assign successfully delegates authority and calculates SLA dueDate'
    );

    // ----------------------------------------------------
    // Scenario 3: FSM State Machine Enforcement
    // ----------------------------------------------------
    // Illegal transition: Jumping directly from 'Assigned' to 'Resolved' or 'Closed'
    const illegalJumpRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${unassignedComplaintId}/status`,
      { status: 'Resolved', remark: 'Fixed prematurely' },
      electricianToken
    );
    assert(
      illegalJumpRes.status === 400 && illegalJumpRes.body.success === false,
      'PATCH /api/complaints/:id/status rejects illegal jump from Assigned -> Resolved (400 Bad Request)'
    );

    // Legal transition: Assigned -> In Progress
    const inProgressRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${unassignedComplaintId}/status`,
      { status: 'In Progress', remark: 'Electrician on site with replacement switch' },
      electricianToken
    );
    assert(
      inProgressRes.status === 200 && inProgressRes.body.data.status === 'In Progress',
      'PATCH /api/complaints/:id/status allows legal transition: Assigned -> In Progress'
    );

    // Illegal transition: Marking 'Resolved' without required action remark
    const noRemarkResolveRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${unassignedComplaintId}/status`,
      { status: 'Resolved', remark: '' },
      electricianToken
    );
    assert(
      noRemarkResolveRes.status === 400,
      'PATCH /api/complaints/:id/status rejects Resolved transition when action remark is missing'
    );

    // Legal transition: In Progress -> Resolved with remark
    const resolveRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${unassignedComplaintId}/status`,
      {
        status: 'Resolved',
        remark: 'Switchboard and wiring replaced with 16A modular switch and tested.'
      },
      electricianToken
    );
    assert(
      resolveRes.status === 200 &&
        resolveRes.body.data.status === 'Resolved' &&
        resolveRes.body.data.resolvedAt !== null,
      'PATCH /api/complaints/:id/status transitions In Progress -> Resolved and sets resolvedAt'
    );

    // Unauthorized authority cannot update another authority ticket (403 Forbidden)
    const unauthorizedUpdateRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${unassignedComplaintId}/status`,
      { status: 'In Progress' },
      wardenToken
    );
    assert(
      unauthorizedUpdateRes.status === 403,
      'PATCH /api/complaints/:id/status denies non-assigned authority (403 Forbidden)'
    );

    // ----------------------------------------------------
    // Scenario 4: Threaded Remarks
    // ----------------------------------------------------
    // Student posts a remark
    const studentRemarkRes = await jsonRequest(
      'POST',
      `/api/complaints/${unassignedComplaintId}/remarks`,
      { text: 'Thank you for the quick replacement!' },
      studentToken
    );
    assert(
      studentRemarkRes.status === 201 &&
        studentRemarkRes.body.success === true &&
        studentRemarkRes.body.data.remarks.length >= 2,
      'POST /api/complaints/:id/remarks allows student to post collaborative remark'
    );

    // Electrician posts a reply remark
    const authorityRemarkRes = await jsonRequest(
      'POST',
      `/api/complaints/${unassignedComplaintId}/remarks`,
      { text: 'You are welcome. Please test and submit feedback to close the ticket.' },
      electricianToken
    );
    assert(
      authorityRemarkRes.status === 201 &&
        authorityRemarkRes.body.data.remarks.some((r) => r.role === 'authority'),
      'POST /api/complaints/:id/remarks allows authority to append threaded reply'
    );

    console.log('\n---------------------------------------------');
    console.log(`Results: ${passed} Passed, ${failed} Failed`);
    console.log('=============================================\n');

    server.close();
    await mongoose.connection.close();
    process.exit(failed > 0 ? 1 : 0);
  } catch (err) {
    console.error('Day 5 Test Runner Error:', err);
    if (server) server.close();
    await mongoose.connection.close();
    process.exit(1);
  }
};

runDay5Tests();
