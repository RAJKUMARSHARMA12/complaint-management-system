const express = require('express');
const { body } = require('express-validator');
const { register, login, getMe, changePassword } = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth');
const { loginLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

// Validation chains
const registerValidation = [
  body('name')
    .isString()
    .withMessage('Name must be a string')
    .trim()
    .notEmpty()
    .withMessage('Name is required')
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('email')
    .isString()
    .withMessage('Email must be a string')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail(),
  body('password')
    .isString()
    .withMessage('Password must be a string')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('phone')
    .optional()
    .isString()
    .withMessage('Phone must be a string')
    .trim()
    .matches(/^[0-9]{10}$/)
    .withMessage('Phone number must be exactly 10 digits'),
  body('studentId')
    .optional()
    .isString()
    .withMessage('Student ID must be a string')
    .trim(),
  body('department')
    .optional()
    .isString()
    .withMessage('Department must be a string')
    .trim()
];

const loginValidation = [
  body('email')
    .isString()
    .withMessage('Email must be a string')
    .trim()
    .notEmpty()
    .withMessage('Email is required')
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail(),
  body('password')
    .isString()
    .withMessage('Password must be a string')
    .notEmpty()
    .withMessage('Password is required')
];

const changePasswordValidation = [
  body('currentPassword')
    .isString()
    .withMessage('Current password must be a string')
    .notEmpty()
    .withMessage('Current password is required'),
  body('newPassword')
    .isString()
    .withMessage('New password must be a string')
    .notEmpty()
    .withMessage('New password is required')
    .isLength({ min: 6 })
    .withMessage('New password must be at least 6 characters long')
];

// Mount endpoints
router.post('/register', registerValidation, register);
router.post('/login', loginLimiter, loginValidation, login);
router.get('/me', protect, getMe);
router.put('/change-password', protect, changePasswordValidation, changePassword);

module.exports = router;
