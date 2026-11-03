const express = require('express');
const { body } = require('express-validator');
const {
  getUsers,
  createAuthority,
  toggleUserStatus
} = require('../controllers/user.controller');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/role');

const router = express.Router();

const authorityValidation = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('email')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .trim()
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('department')
    .trim()
    .notEmpty()
    .withMessage('Department is required')
];

router.get('/', protect, authorize('admin'), getUsers);
router.post('/authority', protect, authorize('admin'), authorityValidation, createAuthority);
router.patch('/:id/status', protect, authorize('admin'), toggleUserStatus);

module.exports = router;
