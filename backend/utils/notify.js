const Notification = require('../models/Notification');

/**
 * Creates and dispatches an in-app notification to a user.
 *
 * @param {Object} options
 * @param {string|mongoose.Types.ObjectId} options.recipient - Recipient user ID
 * @param {string|mongoose.Types.ObjectId|null} [options.sender] - Optional sender user ID
 * @param {string} options.title - Notification header title
 * @param {string} options.message - Descriptive notification body
 * @param {'ASSIGNMENT'|'STATUS_CHANGE'|'REMARK'|'FEEDBACK'|'ESCALATION'|'SYSTEM'} [options.type] - Notification category
 * @param {string|mongoose.Types.ObjectId|null} [options.relatedComplaint] - Optional reference to related complaint
 * @returns {Promise<Notification>}
 */
const createNotification = async ({
  recipient,
  sender = null,
  title,
  message,
  type = 'STATUS_CHANGE',
  relatedComplaint = null
}) => {
  try {
    if (!recipient) {
      console.warn('[Notification Warning] Cannot dispatch notification: missing recipient.');
      return null;
    }

    // Don't notify the sender if recipient is identical to sender
    if (sender && sender.toString() === recipient.toString()) {
      return null;
    }

    const notification = await Notification.create({
      recipient,
      sender,
      title,
      message,
      type,
      relatedComplaint
    });

    return notification;
  } catch (error) {
    console.error(`[Notification Error] Failed to create notification: ${error.message}`);
    // Non-blocking: fail gracefully without crashing calling request
    return null;
  }
};

module.exports = { createNotification };
