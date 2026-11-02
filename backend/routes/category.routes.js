const express = require('express');
const { body } = require('express-validator');
const {
  getCategories,
  getAllCategoriesAdmin,
  createCategory,
  toggleCategoryStatus
} = require('../controllers/category.controller');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/role');

const router = express.Router();

const categoryValidation = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Category name is required')
    .isLength({ max: 50 })
    .withMessage('Category name cannot exceed 50 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 200 })
    .withMessage('Description cannot exceed 200 characters'),
  body('slaDays')
    .optional()
    .isInt({ min: 1, max: 30 })
    .withMessage('SLA days must be an integer between 1 and 30'),
  body('defaultAuthority')
    .optional({ checkFalsy: true })
    .isMongoId()
    .withMessage('Default authority must be a valid User ID')
];

// Public / Authenticated read routes
router.get('/', protect, getCategories);
router.get('/all', protect, authorize('admin'), getAllCategoriesAdmin);

// Admin-only management routes
router.post('/', protect, authorize('admin'), categoryValidation, createCategory);
router.patch('/:id/status', protect, authorize('admin'), toggleCategoryStatus);

module.exports = router;
