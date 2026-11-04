const express = require('express');
const router = express.Router();
const { runEscalationJob } = require('../jobs/escalation.job');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/role');

/**
 * @desc    Manually triggers the SLA escalation job
 * @route   POST /api/jobs/trigger-escalation
 * @access  Private (Admin only)
 */
router.post('/trigger-escalation', protect, authorize('admin'), async (req, res, next) => {
  try {
    const result = await runEscalationJob();
    if (!result.success) {
      return res.status(500).json({
        success: false,
        message: 'Failed to run escalation job',
        error: result.error
      });
    }

    res.status(200).json({
      success: true,
      message: `Escalation job completed. ${result.escalatedCount} complaint(s) escalated.`,
      data: {
        escalatedCount: result.escalatedCount,
        complaints: result.complaints ? result.complaints.map(c => ({
          id: c._id,
          complaintId: c.complaintId,
          title: c.title,
          status: c.status,
          dueDate: c.dueDate,
          isEscalated: c.isEscalated
        })) : []
      }
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
