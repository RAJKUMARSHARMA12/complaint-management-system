const http = require('http');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const app = require('../server');
const Complaint = require('../models/Complaint');
const Category = require('../models/Category');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { runEscalationJob } = require('../jobs/escalation.job');

const TEST_PORT = 5099;
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

const runDay16Tests = async () => {
  console.log('\n=============================================');
  console.log('🧪 Starting Day 16: Automated SLA Escalation Engine Tests');
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
    const studentId = studentLogin.body.data.user.id || studentLogin.body.data.user._id;

    const adminLogin = await jsonRequest('POST', '/api/auth/login', {
      email: 'admin@college.edu',
      password: 'AdminPassword@123'
    });
    assert(adminLogin.status === 200, 'Admin logs in successfully');
    const adminToken = adminLogin.body.data.token;

    // 2. Fetch or create a test category
    let category = await Category.findOne({ isActive: true });
    if (!category) {
      category = await Category.create({
        name: 'SLA Test Category',
        description: 'For testing automated escalation',
        department: 'Infrastructure',
        slaDays: 1,
        isActive: true
      });
    }

    // 3. Create test complaints:
    // Complaint A: Overdue (dueDate in past, status: Assigned, isEscalated: false) -> Should escalate!
    const pastDueDate = new Date(Date.now() - 3600 * 1000 * 24); // 24 hours ago
    const overdueComplaint = await Complaint.create({
      complaintId: `CMP-TEST-${Date.now().toString().slice(-4)}`,
      title: 'Water pipe leaking heavily in corridor',
      description: 'Major leak causing flooding across the corridor outside room 204.',
      category: category._id,
      location: 'Block A, 2nd Floor',
      priority: 'High',
      status: 'Assigned',
      dueDate: pastDueDate,
      isEscalated: false,
      createdBy: studentId
    });
    assert(overdueComplaint.isEscalated === false, 'Created overdue test complaint with isEscalated=false');

    // Complaint B: Not overdue (dueDate in future, status: In Progress, isEscalated: false) -> Should NOT escalate!
    const futureDueDate = new Date(Date.now() + 3600 * 1000 * 48); // 48 hours in future
    const futureComplaint = await Complaint.create({
      complaintId: `CMP-FUTURE-${Date.now().toString().slice(-4)}`,
      title: 'Light bulb replacement in reading room',
      description: 'The ceiling bulb in the corner reading room is flickering constantly.',
      category: category._id,
      location: 'Library Reading Room 3',
      priority: 'Low',
      status: 'In Progress',
      dueDate: futureDueDate,
      isEscalated: false,
      createdBy: studentId
    });

    // Complaint C: Already Resolved (past dueDate, status: Resolved) -> Should NOT escalate!
    const resolvedComplaint = await Complaint.create({
      complaintId: `CMP-RESOLVED-${Date.now().toString().slice(-4)}`,
      title: 'Broken chair in classroom 101',
      description: 'Chair leg is broken and has already been fixed by carpentry.',
      category: category._id,
      location: 'Classroom 101',
      priority: 'Medium',
      status: 'Resolved',
      dueDate: pastDueDate,
      isEscalated: false,
      resolvedAt: new Date(),
      createdBy: studentId
    });

    // 4. Test runEscalationJob function directly
    const runResult = await runEscalationJob();
    assert(runResult.success === true, 'runEscalationJob executes successfully');
    assert(runResult.escalatedCount >= 1, `runEscalationJob escalated at least 1 complaint (escalated: ${runResult.escalatedCount})`);

    // Verify overdue complaint in DB
    const checkedOverdue = await Complaint.findById(overdueComplaint._id);
    assert(checkedOverdue.isEscalated === true, 'Overdue complaint is marked isEscalated=true');
    assert(checkedOverdue.escalatedAt !== null, 'Overdue complaint has escalatedAt timestamp recorded');

    // Verify future complaint untouched
    const checkedFuture = await Complaint.findById(futureComplaint._id);
    assert(checkedFuture.isEscalated === false, 'Future complaint remains isEscalated=false');

    // Verify resolved complaint untouched
    const checkedResolved = await Complaint.findById(resolvedComplaint._id);
    assert(checkedResolved.isEscalated === false, 'Resolved complaint remains isEscalated=false');

    // Verify admin notifications dispatched
    const adminUser = await User.findOne({ role: 'admin' });
    const notification = await Notification.findOne({
      recipient: adminUser._id,
      type: 'ESCALATION',
      relatedComplaint: overdueComplaint._id
    });
    assert(notification !== null, 'Notification of type ESCALATION created for Admin');
    assert(notification.title.includes('SLA Breach') || notification.title.includes('Escalation'), 'Notification title references SLA Breach or Escalation');

    // 5. Test manual trigger endpoint POST /api/jobs/trigger-escalation
    // Non-admin (student) should be rejected with 403 Forbidden
    const studentTrigger = await jsonRequest('POST', '/api/jobs/trigger-escalation', {}, studentToken);
    assert(studentTrigger.status === 403, 'Student blocked from POST /api/jobs/trigger-escalation (403 Forbidden)');

    // Unauthenticated user should be rejected with 401 Unauthorized
    const unauthTrigger = await jsonRequest('POST', '/api/jobs/trigger-escalation', {}, null);
    assert(unauthTrigger.status === 401, 'Unauthenticated user blocked from trigger endpoint (401 Unauthorized)');

    // Admin should trigger escalation successfully
    const adminTrigger = await jsonRequest('POST', '/api/jobs/trigger-escalation', {}, adminToken);
    assert(adminTrigger.status === 200, 'Admin can trigger manual escalation via POST /api/jobs/trigger-escalation');
    assert(adminTrigger.body && adminTrigger.body.success === true, 'Trigger response returns success=true');
    assert(typeof adminTrigger.body.data.escalatedCount === 'number', 'Trigger response contains escalatedCount number');

    // Cleanup test records
    await Complaint.deleteMany({
      _id: { $in: [overdueComplaint._id, futureComplaint._id, resolvedComplaint._id] }
    });
    await Notification.deleteMany({
      relatedComplaint: { $in: [overdueComplaint._id, futureComplaint._id, resolvedComplaint._id] }
    });

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
    console.log(`\nDay 16 Test Summary: Passed: ${passed}, Failed: ${failed}`);
    process.exit(failed > 0 ? 1 : 0);
  }
};

runDay16Tests();
