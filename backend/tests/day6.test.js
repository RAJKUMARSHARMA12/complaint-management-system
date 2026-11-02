const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');
const Notification = require('../models/Notification');
const Complaint = require('../models/Complaint');

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

const runDay6Tests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 6: Feedback Loop & Notification Subsystem Tests');
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

    // 1. Authenticate Actors
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

    const studentLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'aarav.mehta@college.edu',
      password: 'StudentPassword@123'
    });
    const studentToken = studentLogin.body.data.token;
    const studentId = studentLogin.body.data.user.id;

    // Get categories
    const categoriesRes = await jsonRequest('GET', '/api/categories', null, studentToken);
    const hostelCat = categoriesRes.body.data.find((c) => c.name === 'Hostel Maintenance');

    // ----------------------------------------------------
    // Scenario 1: End-to-End Lifecycle with Notification Triggers
    // ----------------------------------------------------
    // Step A: Student lodges complaint (auto-assigned to Warden)
    const lodgeRes = await multipartRequest(
      'POST',
      '/api/complaints',
      {
        title: 'Ceiling fan making screeching noise in Room 104',
        description: 'The bearings seem damaged and causing severe vibrations all night.',
        category: hostelCat.id,
        location: 'Hostel Block A, Room 104',
        priority: 'Medium',
        isAnonymous: 'false'
      },
      [],
      studentToken
    );
    const complaintId = lodgeRes.body.data.id;
    assert(
      lodgeRes.status === 201 && lodgeRes.body.data.status === 'Assigned',
      'Step 1: Student lodges complaint auto-assigned to Warden'
    );

    // Verify Warden received notification of assignment
    const wardenNotifRes1 = await jsonRequest('GET', '/api/notifications', null, wardenToken);
    assert(
      wardenNotifRes1.status === 200 &&
        wardenNotifRes1.body.data.notifications.some(
          (n) => n.type === 'ASSIGNMENT' && n.message.includes(lodgeRes.body.data.complaintId)
        ),
      'Step 2: Notification hook dispatches ASSIGNMENT alert to authority'
    );

    // Step B: Authority moves ticket: Assigned -> In Progress
    const inProgRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${complaintId}/status`,
      { status: 'In Progress', remark: 'Inspected fan assembly in Room 104' },
      wardenToken
    );
    assert(inProgRes.status === 200, 'Step 3: Authority moves status to In Progress');

    // Verify Student received STATUS_CHANGE notification
    const studentNotifRes1 = await jsonRequest('GET', '/api/notifications', null, studentToken);
    assert(
      studentNotifRes1.body.data.notifications.some(
        (n) => n.type === 'STATUS_CHANGE' && n.message.includes("'In Progress'")
      ),
      'Step 4: Student receives STATUS_CHANGE notification for In Progress'
    );

    // Step C: Authority adds remark
    const remarkRes = await jsonRequest(
      'POST',
      `/api/complaints/${complaintId}/remarks`,
      { text: 'Replacement fan capacitor ordered from store.' },
      wardenToken
    );
    assert(remarkRes.status === 201, 'Step 5: Authority posts action remark');

    // Verify Student received REMARK notification
    const studentNotifRes2 = await jsonRequest('GET', '/api/notifications', null, studentToken);
    assert(
      studentNotifRes2.body.data.notifications.some((n) => n.type === 'REMARK'),
      'Step 6: Student receives REMARK notification when authority comments'
    );

    // ----------------------------------------------------
    // Scenario 2: Feedback Constraints & Terminal Closure
    // ----------------------------------------------------
    // Constraint Test 1: Submitting feedback when status is NOT Resolved fails
    const prematureFeedbackRes = await jsonRequest(
      'POST',
      `/api/complaints/${complaintId}/feedback`,
      { rating: 5, comment: 'Premature review' },
      studentToken
    );
    assert(
      prematureFeedbackRes.status === 400 &&
        prematureFeedbackRes.body.message.includes('Resolved'),
      'Feedback rejected when status is not Resolved (400 Bad Request)'
    );

    // Step D: Authority marks complaint Resolved with action remark
    const resolveRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${complaintId}/status`,
      {
        status: 'Resolved',
        remark: 'Installed new fan capacitor and verified smooth operation with zero noise.'
      },
      wardenToken
    );
    assert(resolveRes.status === 200 && resolveRes.body.data.status === 'Resolved', 'Step 7: Ticket marked Resolved');

    // Constraint Test 2: Non-owner cannot submit feedback (403 Forbidden)
    const otherStudentLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'priya.sharma@college.edu',
      password: 'StudentPassword@123'
    });
    const otherStudentToken = otherStudentLogin.body.data.token;

    const nonOwnerFeedbackRes = await jsonRequest(
      'POST',
      `/api/complaints/${complaintId}/feedback`,
      { rating: 4 },
      otherStudentToken
    );
    assert(
      nonOwnerFeedbackRes.status === 403,
      'Non-owner student blocked from submitting feedback (403 Forbidden)'
    );

    // Constraint Test 3: Invalid rating (< 1 or > 5) fails validation
    const badRatingRes = await jsonRequest(
      'POST',
      `/api/complaints/${complaintId}/feedback`,
      { rating: 6, comment: 'Too high' },
      studentToken
    );
    assert(badRatingRes.status === 400, 'Invalid rating (6 out of 5) rejected (400 Bad Request)');

    // Step E: Student submits valid feedback -> transitions to Closed
    const validFeedbackRes = await jsonRequest(
      'POST',
      `/api/complaints/${complaintId}/feedback`,
      {
        rating: 5,
        comment: 'Fan is working completely silently now. Excellent and rapid work!'
      },
      studentToken
    );
    assert(
      validFeedbackRes.status === 200 &&
        validFeedbackRes.body.success === true &&
        validFeedbackRes.body.data.status === 'Closed' &&
        validFeedbackRes.body.data.closedAt !== null &&
        validFeedbackRes.body.data.feedback.rating === 5,
      'Step 8: Student submits feedback; ticket transitions to terminal state Closed'
    );

    // Constraint Test 4: Cannot submit feedback twice
    const duplicateFeedbackRes = await jsonRequest(
      'POST',
      `/api/complaints/${complaintId}/feedback`,
      { rating: 4 },
      studentToken
    );
    assert(
      duplicateFeedbackRes.status === 400,
      'Duplicate feedback on closed complaint rejected (400 Bad Request)'
    );

    // Constraint Test 5: Closed tickets are immutable (cannot update status)
    const updateClosedRes = await jsonRequest(
      'PATCH',
      `/api/complaints/${complaintId}/status`,
      { status: 'In Progress' },
      wardenToken
    );
    assert(
      updateClosedRes.status === 400,
      'Closed complaint is immutable; further status updates rejected'
    );

    // Verify Authority received FEEDBACK notification
    const wardenNotifRes2 = await jsonRequest('GET', '/api/notifications', null, wardenToken);
    assert(
      wardenNotifRes2.body.data.notifications.some(
        (n) => n.type === 'FEEDBACK' && n.message.includes('5-star')
      ),
      'Step 9: Authority receives FEEDBACK notification with satisfaction score'
    );

    // ----------------------------------------------------
    // Scenario 3: Notification Inbox & Read Flags
    // ----------------------------------------------------
    const inboxBefore = await jsonRequest('GET', '/api/notifications', null, wardenToken);
    const unreadCountBefore = inboxBefore.body.data.unreadCount;
    assert(unreadCountBefore > 0, 'Authority inbox has unread notifications');

    const firstNotifId = inboxBefore.body.data.notifications[0].id;

    // Mark single notification as read
    const markOneRes = await jsonRequest(
      'PATCH',
      `/api/notifications/${firstNotifId}/read`,
      null,
      wardenToken
    );
    assert(
      markOneRes.status === 200 && markOneRes.body.data.isRead === true,
      'PATCH /api/notifications/:id/read marks single notification as read'
    );

    // Mark all notifications as read
    const markAllRes = await jsonRequest(
      'PATCH',
      '/api/notifications/read-all',
      null,
      wardenToken
    );
    assert(
      markAllRes.status === 200 && markAllRes.body.success === true,
      'PATCH /api/notifications/read-all marks entire inbox as read'
    );

    const inboxAfter = await jsonRequest('GET', '/api/notifications', null, wardenToken);
    assert(
      inboxAfter.body.data.unreadCount === 0 &&
        inboxAfter.body.data.notifications.every((n) => n.isRead === true),
      'Inbox confirms unreadCount is now 0'
    );

    console.log('\n---------------------------------------------');
    console.log(`Results: ${passed} Passed, ${failed} Failed`);
    console.log('=============================================\n');

    server.close();
    await mongoose.connection.close();
    process.exit(failed > 0 ? 1 : 0);
  } catch (err) {
    console.error('Day 6 Test Runner Error:', err);
    if (server) server.close();
    await mongoose.connection.close();
    process.exit(1);
  }
};

runDay6Tests();
