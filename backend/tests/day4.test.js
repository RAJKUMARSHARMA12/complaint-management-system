const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');
const Category = require('../models/Category');

const TEST_PORT = 5098;
let server;

// Helper to make multipart or JSON requests
const jsonRequest = (method, path, body = null, token = null) => {
  return new Promise((resolve, reject) => {
    const dataString = body ? JSON.stringify(body) : '';
    const headers = {
      'Content-Type': 'application/json'
    };
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

    // Append text fields
    for (const [key, value] of Object.entries(fields)) {
      let fieldHeader = `--${boundary}\r\n`;
      fieldHeader += `Content-Disposition: form-data; name="${key}"\r\n\r\n`;
      fieldHeader += `${value}\r\n`;
      bodyBuffer = Buffer.concat([bodyBuffer, Buffer.from(fieldHeader, 'utf8')]);
    }

    // Append binary files
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

const runDay4Tests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 4: Category CRUD & Complaint Lodging Tests');
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

    // 1. Authenticate Admin and Student
    const adminLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'admin@college.edu',
      password: 'AdminPassword@123'
    });
    const adminToken = adminLogin.body.data.token;

    const studentLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'aarav.mehta@college.edu',
      password: 'StudentPassword@123'
    });
    const studentToken = studentLogin.body.data.token;

    // Test 1: GET /api/categories returns active categories
    const catRes = await jsonRequest('GET', '/api/categories', null, studentToken);
    assert(
      catRes.status === 200 &&
        catRes.body.success === true &&
        Array.isArray(catRes.body.data) &&
        catRes.body.data.length >= 5,
      'GET /api/categories returns active category list'
    );

    const hostelCategory = catRes.body.data.find((c) => c.name === 'Hostel Maintenance');
    const sanitationCategory = catRes.body.data.find(
      (c) => c.name === 'Sanitation & Campus Cleanliness'
    );

    // Test 2: Admin creates new category (unique name per run)
    const testCategoryName = `Sports & Gymnasium ${Date.now()}`;
    const createCatRes = await jsonRequest(
      'POST',
      '/api/categories',
      {
        name: testCategoryName,
        description: 'Gym equipment, badminton court, sports gear',
        slaDays: 4,
        icon: 'sports_tennis'
      },
      adminToken
    );
    assert(
      createCatRes.status === 201 &&
        createCatRes.body.success === true &&
        createCatRes.body.data.name === testCategoryName &&
        createCatRes.body.data.slaDays === 4,
      'POST /api/categories creates new category (Admin only)'
    );

    const newCatId = createCatRes.body.data.id;

    // Test 3: Non-admin cannot create category (403 Forbidden)
    const forbidCatRes = await jsonRequest(
      'POST',
      '/api/categories',
      {
        name: 'Illegal Category',
        slaDays: 2
      },
      studentToken
    );
    assert(
      forbidCatRes.status === 403,
      'POST /api/categories is blocked for students (403 Forbidden)'
    );

    // Test 4: Toggle category status
    const toggleRes = await jsonRequest(
      'PATCH',
      `/api/categories/${newCatId}/status`,
      { isActive: false },
      adminToken
    );
    assert(
      toggleRes.status === 200 &&
        toggleRes.body.success === true &&
        toggleRes.body.data.isActive === false,
      'PATCH /api/categories/:id/status toggles category active flag'
    );

    // Test 5: Inactive category no longer appears in GET /api/categories
    const activeCatsAfter = await jsonRequest('GET', '/api/categories', null, studentToken);
    const foundInactive = activeCatsAfter.body.data.find((c) => c.id === newCatId);
    assert(foundInactive === undefined, 'Inactive category is filtered out from active list');

    // Test 6: Multipart complaint lodging with 2 images & auto-routing
    // Minimal 1x1 PNG bytes
    const fakePng = Buffer.from(
      '89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c63000100000500010d0a2d420000000049454e44ae426082',
      'hex'
    );

    const complaintPayload = {
      title: 'Broken window in Hostel Room 204',
      description: 'The latch is broken and the glass pane has a crack, letting rain inside.',
      category: hostelCategory.id,
      location: 'Hostel Block B, 2nd Floor, Room 204',
      priority: 'High',
      isAnonymous: false
    };

    const files = [
      {
        fieldname: 'images',
        filename: 'evidence1.png',
        mimetype: 'image/png',
        buffer: fakePng
      },
      {
        fieldname: 'images',
        filename: 'evidence2.png',
        mimetype: 'image/png',
        buffer: fakePng
      }
    ];

    const lodgingRes = await multipartRequest(
      'POST',
      '/api/complaints',
      complaintPayload,
      files,
      studentToken
    );

    assert(
      lodgingRes.status === 201 &&
        lodgingRes.body.success === true &&
        lodgingRes.body.data.complaintId.startsWith('CMP-') &&
        lodgingRes.body.data.status === 'Assigned' &&
        lodgingRes.body.data.images.length === 2 &&
        lodgingRes.body.data.dueDate !== null,
      'POST /api/complaints (multipart) creates complaint with images and auto-assigns due to defaultAuthority'
    );

    // Test 7: Complaint without defaultAuthority defaults to 'Submitted'
    const unassignedPayload = {
      title: 'Corridor lights flickering',
      description: 'Second floor main corridor lights keep flickering intermittently.',
      category: sanitationCategory.id, // sanitation has defaultAuthority: null
      location: 'Academic Block 1, 2nd Floor Corridor',
      priority: 'Medium',
      isAnonymous: true
    };

    const unassignedRes = await multipartRequest(
      'POST',
      '/api/complaints',
      unassignedPayload,
      [],
      studentToken
    );

    assert(
      unassignedRes.status === 201 &&
        unassignedRes.body.data.status === 'Submitted' &&
        unassignedRes.body.data.assignedTo === null &&
        unassignedRes.body.data.isAnonymous === true,
      'POST /api/complaints without defaultAuthority sets status=Submitted and supports whistleblower mode'
    );

    // Test 8: Student retrieves their own complaints
    const myComplaintsRes = await jsonRequest('GET', '/api/complaints/my', null, studentToken);
    assert(
      myComplaintsRes.status === 200 &&
        myComplaintsRes.body.success === true &&
        Array.isArray(myComplaintsRes.body.data.complaints) &&
        myComplaintsRes.body.data.complaints.length >= 2 &&
        myComplaintsRes.body.data.pagination.total >= 2,
      'GET /api/complaints/my returns student complaints list with pagination'
    );

    // Test 9: Status filtering on GET /api/complaints/my?status=Assigned
    const filteredRes = await jsonRequest(
      'GET',
      '/api/complaints/my?status=Assigned',
      null,
      studentToken
    );
    assert(
      filteredRes.status === 200 &&
        filteredRes.body.data.complaints.every((c) => c.status === 'Assigned'),
      'GET /api/complaints/my?status=Assigned filters complaints accurately'
    );

    // Test 10: Non-student cannot lodge complaints (403 Forbidden)
    const adminLodgeRes = await multipartRequest(
      'POST',
      '/api/complaints',
      complaintPayload,
      [],
      adminToken
    );
    assert(
      adminLodgeRes.status === 403,
      'POST /api/complaints blocked for non-students (403 Forbidden)'
    );

    console.log('\n---------------------------------------------');
    console.log(`Results: ${passed} Passed, ${failed} Failed`);
    console.log('=============================================\n');

    server.close();
    await mongoose.connection.close();
    process.exit(failed > 0 ? 1 : 0);
  } catch (err) {
    console.error('Day 4 Test Runner Error:', err);
    if (server) server.close();
    await mongoose.connection.close();
    process.exit(1);
  }
};

runDay4Tests();
