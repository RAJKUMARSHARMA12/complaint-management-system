const Notification = require('../models/Notification');

// @desc    Get notification inbox for authenticated user
// @route   GET /api/notifications
// @access  Protected (All authenticated users)
const getNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 20;
    const skip = (pageNum - 1) * limitNum;

    const query = { recipient: req.user._id };

    const unreadCount = await Notification.countDocuments({
      recipient: req.user._id,
      isRead: false
    });

    const total = await Notification.countDocuments(query);
    const notifications = await Notification.find(query)
      .populate('sender', 'name role')
      .populate('relatedComplaint', 'complaintId title status')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    const formatted = notifications.map((n) => ({
      id: n._id,
      title: n.title,
      message: n.message,
      type: n.type,
      relatedComplaint: n.relatedComplaint
        ? {
            id: n.relatedComplaint._id,
            complaintId: n.relatedComplaint.complaintId,
            title: n.relatedComplaint.title,
            status: n.relatedComplaint.status
          }
        : null,
      sender: n.sender ? { id: n.sender._id, name: n.sender.name, role: n.sender.role } : null,
      isRead: n.isRead,
      createdAt: n.createdAt
    }));

    return res.status(200).json({
      success: true,
      data: {
        unreadCount,
        notifications: formatted,
        pagination: {
          total,
          page: pageNum,
          pages: Math.ceil(total / limitNum) || 1,
          limit: limitNum
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mark single notification as read
// @route   PATCH /api/notifications/:id/read
// @access  Protected (Recipient only)
const markNotificationRead = async (req, res, next) => {
  try {
    const { id } = req.params;

    const notification = await Notification.findOne({
      _id: id,
      recipient: req.user._id
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found or access denied.'
      });
    }

    notification.isRead = true;
    await notification.save();

    return res.status(200).json({
      success: true,
      message: 'Notification marked as read',
      data: {
        id: notification._id,
        isRead: notification.isRead
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mark all user's notifications as read
// @route   PATCH /api/notifications/read-all
// @access  Protected (Recipient only)
const markAllNotificationsRead = async (req, res, next) => {
  try {
    const result = await Notification.updateMany(
      { recipient: req.user._id, isRead: false },
      { $set: { isRead: true } }
    );

    return res.status(200).json({
      success: true,
      message: 'All notifications marked as read',
      data: {
        modifiedCount: result.modifiedCount
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getNotifications,
  markNotificationRead,
  markAllNotificationsRead
};
