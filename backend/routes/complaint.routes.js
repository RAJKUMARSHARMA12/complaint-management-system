const express = require('express');
const { body } = require('express-validator');
const {
  createComplaint,
  getMyComplaints,
  getAssignedComplaints,
  getAllComplaintsAdmin,
  getComplaintById,
  assignComplaint,
  updateComplaintStatus,
  addRemark,
  submitFeedback
} = require('../controllers/complaint.controller');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/role');
const upload = require('../middleware/upload');

const router = express.Router();

const complaintValidation = [
  body('title')
    .trim()
    .notEmpty()
    .withMessage('Title is required')
    .isLength({ min: 5, max: 100 })
    .withMessage('Title must be between 5 and 100 characters'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ min: 20, max: 1000 })
    .withMessage('Description must be between 20 and 1000 characters'),
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .isMongoId()
    .withMessage('Category must be a valid ID'),
  body('location')
    .trim()
    .notEmpty()
    .withMessage('Location is required')
    .isLength({ max: 100 })
    .withMessage('Location cannot exceed 100 characters'),
  body('priority')
    .optional()
    .isIn(['Low', 'Medium', 'High', 'Urgent'])
    .withMessage('Priority must be Low, Medium, High, or Urgent')
];

const statusValidation = [
  body('status')
    .notEmpty()
    .withMessage('Status is required')
    .isIn(['Submitted', 'Assigned', 'In Progress', 'Resolved', 'Closed'])
    .withMessage('Invalid status state'),
  body('remark')
    .optional()
    .trim()
];

const remarkValidation = [
  body('text')
    .trim()
    .notEmpty()
    .withMessage('Remark text is required')
    .isLength({ min: 2, max: 500 })
    .withMessage('Remark must be between 2 and 500 characters')
];

// Student complaint submission & personal history
router.post(
  '/',
  protect,
  authorize('student'),
  upload.array('images', 3),
  complaintValidation,
  createComplaint
);

router.get('/my', protect, authorize('student'), getMyComplaints);

// Authority assigned queue
router.get('/assigned', protect, authorize('authority'), getAssignedComplaints);

// Admin master list (multi-parameter search & filter)
router.get('/', protect, authorize('admin'), getAllComplaintsAdmin);

// Detailed inspection with whistleblower privacy scrubber
router.get('/:id', protect, getComplaintById);

// Admin assignment & delegation
router.patch('/:id/assign', protect, authorize('admin'), assignComplaint);

// Status progression enforcing FSM rules
router.patch(
  '/:id/status',
  protect,
  authorize('authority', 'admin'),
  statusValidation,
  updateComplaintStatus
);

// Threaded collaborative remarks
router.post('/:id/remarks', protect, remarkValidation, addRemark);

// Student feedback & terminal closure
router.post(
  '/:id/feedback',
  protect,
  authorize('student'),
  [
    body('rating')
      .notEmpty()
      .withMessage('Rating is required')
      .isInt({ min: 1, max: 5 })
      .withMessage('Rating must be an integer between 1 and 5'),
    body('comment')
      .optional()
      .trim()
      .isLength({ max: 300 })
      .withMessage('Comment cannot exceed 300 characters')
  ],
  submitFeedback
);

module.exports = router;
