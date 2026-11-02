const express = require('express');
const { body } = require('express-validator');
const {
  createComplaint,
  getMyComplaints
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

// Student complaint routes
router.post(
  '/',
  protect,
  authorize('student'),
  upload.array('images', 3),
  complaintValidation,
  createComplaint
);

router.get('/my', protect, authorize('student'), getMyComplaints);

module.exports = router;
