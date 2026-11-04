const cron = require('node-cron');
const Complaint = require('../models/Complaint');
const User = require('../models/User');
const { createNotification } = require('../utils/notify');

/**
 * Executes the SLA escalation process:
 * Finds all active complaints where:
 * - status NOT IN ('Resolved', 'Closed')
 * - dueDate is defined and < now
 * - isEscalated is false
 *
 * Marks them isEscalated = true, sets escalatedAt = now,
 * and creates urgent in-app notifications for all administrators.
 *
 * @returns {Promise<{ success: boolean, escalatedCount: number, complaints: Array }>}
 */
const runEscalationJob = async () => {
  const now = new Date();
  console.log(`[SLA Escalation Engine] Starting escalation audit at ${now.toISOString()}...`);

  try {
    // 1. Query for breached complaints
    const overdueComplaints = await Complaint.find({
      status: { $nin: ['Resolved', 'Closed'] },
      dueDate: { $ne: null, $lt: now },
      isEscalated: false
    }).populate('category', 'name slaDays');

    if (overdueComplaints.length === 0) {
      console.log('[SLA Escalation Engine] No SLA breaches detected. Zero complaints escalated.');
      return {
        success: true,
        escalatedCount: 0,
        complaints: []
      };
    }

    console.log(`[SLA Escalation Engine] Found ${overdueComplaints.length} overdue complaint(s) requiring escalation.`);

    // 2. Fetch all admin users to dispatch urgent notifications
    const adminUsers = await User.find({ role: 'admin', isActive: true });

    const escalatedIds = [];

    for (const complaint of overdueComplaints) {
      complaint.isEscalated = true;
      complaint.escalatedAt = now;
      await complaint.save();
      escalatedIds.push(complaint.complaintId);

      const categoryName = complaint.category ? complaint.category.name : 'General';
      const hoursOverdue = Math.round((now - complaint.dueDate) / (1000 * 60 * 60));

      // Notify all admin users
      for (const admin of adminUsers) {
        await createNotification({
          recipient: admin._id,
          title: `⚠️ SLA Breach Alert: ${complaint.complaintId}`,
          message: `Complaint "${complaint.title}" (${categoryName}) is ${hoursOverdue}h past its SLA due date. Immediate administrative intervention required.`,
          type: 'ESCALATION',
          relatedComplaint: complaint._id
        });
      }
    }

    console.log(`[SLA Escalation Engine] Successfully escalated ${escalatedIds.length} complaint(s): [${escalatedIds.join(', ')}].`);

    return {
      success: true,
      escalatedCount: overdueComplaints.length,
      complaints: overdueComplaints
    };
  } catch (error) {
    console.error(`[SLA Escalation Engine] Fatal error during escalation job: ${error.message}`);
    return {
      success: false,
      error: error.message,
      escalatedCount: 0
    };
  }
};

/**
 * Initializes the background cron scheduler.
 * Runs daily at midnight: '0 0 * * *'
 */
const initEscalationJob = () => {
  cron.schedule('0 0 * * *', async () => {
    console.log('[Cron Daemon] Triggering scheduled daily SLA escalation audit...');
    await runEscalationJob();
  });
  console.log('[Cron Daemon] SLA Escalation cron job registered (schedule: 0 0 * * * - daily midnight).');
};

module.exports = {
  runEscalationJob,
  initEscalationJob
};
