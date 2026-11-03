const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');
const Category = require('../models/Category');
const Complaint = require('../models/Complaint');
const User = require('../models/User');

const TEST_PORT = 5096;
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

    for (const file of files) {
      let fileHeader = `--${boundary}\r\n`;
      fileHeader += `Content-Disposition: form-data; name="${file.fieldname}"; filename="${file.filename}"\r\n`;
      fileHeader += `Content-Type: ${file.mimetype}\r\n\r\n`;
      bodyBuffer = Buffer.concat([
        bodyBuffer,
        Buffer.from(fileHeader, 'utf8'),
        file.buffer,
        Buffer.from('\r\n', 'utf8')
      ]);
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

const runDay14Tests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 14: Full Lifecycle Integration Audit');
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

    // Setup Category without defaultAuthority so it requires admin delegation
    const testCat = await Category.create({
      name: `Civil Works ${Date.now()}`,
      description: 'Masonry and road repairs',
      slaDays: 5,
      isActive: true
    });

    // 1. Student logs in
    const studentLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'aarav.mehta@college.edu',
      password: 'StudentPassword@123'
    });
    assert(studentLogin.status === 200, 'Step 1: Student logs in successfully');
    const studentToken = studentLogin.body.data.token;

    // 2. Student lodges a complaint with image evidence (multipart)
    const fakePng = Buffer.from(
      '89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c63000100000500010d0a2d420000000049454e44ae426082',
      'hex'
    );
    const files = [
      {
        fieldname: 'images',
        filename: 'pavement.png',
        mimetype: 'image/png',
        buffer: fakePng
      }
    ];

    const lodgeRes = await multipartRequest(
      'POST',
      '/api/complaints',
      {
        title: 'Cracked Pavement Outside Library',
        description: 'Deep pavement fissure causing tripping hazard near library entrance',
        category: testCat._id.toString(),
        location: 'Central Library Walkway',
        priority: 'High',
        isAnonymous: 'false'
      },
      files,
      studentToken
    );

    assert(lodgeRes.status === 201, 'Step 1: Student lodges complaint successfully with photo');
    const complaintId = lodgeRes.body.data.id;
    assert(lodgeRes.body.data.status === 'Submitted', 'Initial status is Submitted (unassigned)');

    // 3. Admin logs in
    const adminLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'admin@college.edu',
      password: 'AdminPassword@123'
    });
    assert(adminLogin.status === 200, 'Step 2: Admin logs in successfully');
    const adminToken = adminLogin.body.data.token;

    // 4. Admin reviews all complaints and finds newly lodged ticket
    const adminListRes = await jsonRequest('GET', '/api/complaints?status=Submitted', null, adminToken);
    assert(adminListRes.status === 200, 'Step 2: Admin queries unassigned queue');
    const foundTicket = adminListRes.body.data.complaints.find((c) => c.id === complaintId || c._id === complaintId);
    assert(!!foundTicket, 'Admin sees the new ticket in Submitted queue');

    // 5. Admin fetches authority staff to delegate
    const staffRes = await jsonRequest('GET', '/api/users?role=authority', null, adminToken);
    assert(staffRes.status === 200 && staffRes.body.data.users.length > 0, 'Admin fetches authority staff list');
    const assignedAuthority =
      staffRes.body.data.users.find((u) => u.email === 'warden.hostel@college.edu') ||
      staffRes.body.data.users[0];

    // 6. Admin assigns complaint to authority
    const assignRes = await jsonRequest('PATCH', `/api/complaints/${complaintId}/assign`, {
      authorityId: assignedAuthority.id,
      remark: 'Please inspect cracked pavement urgently'
    }, adminToken);
    assert(assignRes.status === 200, 'Step 2: Admin delegates ticket to authority');
    assert(assignRes.body.data.status === 'Assigned', 'Status updated to Assigned');
    assert(!!assignRes.body.data.dueDate, 'SLA due date computed from category slaDays');

    // 7. Authority logs in (using seeded warden.hostel credentials)
    const wardenLogin = await jsonRequest('POST', '/api/auth/login', {
      email: assignedAuthority.email,
      password: 'WardenPassword@123'
    });
    assert(wardenLogin.status === 200, 'Step 3: Authority logs in successfully');
    const authorityToken = wardenLogin.body.data.token;

    // 8. Authority views assigned tickets
    const assignedQueueRes = await jsonRequest('GET', '/api/complaints/assigned', null, authorityToken);
    assert(assignedQueueRes.status === 200, 'Authority fetches assigned queue');

    // 9. Authority moves status to In Progress
    const inProgressRes = await jsonRequest('PATCH', `/api/complaints/${complaintId}/status`, {
      status: 'In Progress',
      remark: 'Technician dispatched to inspect masonry work'
    }, authorityToken);
    assert(inProgressRes.status === 200, 'Step 3: Authority transitions status to In Progress');
    assert(inProgressRes.body.data.status === 'In Progress', 'Ticket status confirmed In Progress');

    // 10. Authority appends progress remark
    const remarkRes = await jsonRequest('POST', `/api/complaints/${complaintId}/remarks`, {
      text: 'Fresh cement mortar applied. Curing for 24 hours.'
    }, authorityToken);
    assert(remarkRes.status === 201 || remarkRes.status === 200, 'Authority appends operational remark');

    // 11. Authority marks ticket as Resolved
    const resolveRes = await jsonRequest('PATCH', `/api/complaints/${complaintId}/status`, {
      status: 'Resolved',
      remark: 'Pavement leveling complete. Safety barrier removed.'
    }, authorityToken);
    assert(resolveRes.status === 200, 'Step 3: Authority transitions status to Resolved');
    assert(resolveRes.body.data.status === 'Resolved', 'Ticket status confirmed Resolved');
    assert(!!resolveRes.body.data.resolvedAt, 'resolvedAt timestamp recorded');

    // 12. Student inspects resolved ticket
    const studentDetailRes = await jsonRequest('GET', `/api/complaints/${complaintId}`, null, studentToken);
    assert(studentDetailRes.status === 200, 'Step 4: Student fetches complaint details');
    assert(studentDetailRes.body.data.status === 'Resolved', 'Student verifies status is Resolved');
    assert(studentDetailRes.body.data.remarks.length >= 2, 'Student sees authority remarks timeline');

    // 13. Student rates 5-star feedback and submits closure
    const feedbackRes = await jsonRequest('POST', `/api/complaints/${complaintId}/feedback`, {
      rating: 5,
      comment: 'Excellent and quick repair work. Thank you!'
    }, studentToken);
    assert(feedbackRes.status === 200, 'Step 4: Student submits 5-star feedback');
    assert(feedbackRes.body.data.status === 'Closed', 'Ticket transitioned to terminal state Closed');
    assert(feedbackRes.body.data.feedback.rating === 5, 'Feedback score 5 recorded');
    assert(!!feedbackRes.body.data.closedAt, 'closedAt timestamp recorded');

    // 14. Terminal immutability verification: Closed complaint rejects further status updates
    const invalidUpdateRes = await jsonRequest('PATCH', `/api/complaints/${complaintId}/status`, {
      status: 'In Progress',
      remark: 'Attempting illegal update on closed complaint'
    }, authorityToken);
    assert(invalidUpdateRes.status === 400, 'Step 4: Closed complaint is strictly immutable (400 Bad Request)');

    // Cleanup test category and complaint
    await Complaint.findByIdAndDelete(complaintId);
    await Category.findByIdAndDelete(testCat._id);

  } catch (err) {
    console.error('Test execution error:', err);
    failed++;
  } finally {
    if (server) {
      server.close();
    }
    console.log(`\nDay 14 Lifecycle Test Summary: Passed: ${passed}, Failed: ${failed}\n`);
    process.exit(failed > 0 ? 1 : 0);
  }
};

runDay14Tests();
