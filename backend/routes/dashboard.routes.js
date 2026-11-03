const express = require('express');
const router = express.Router();
const {
  getStats,
  getByCategory,
  getByStatus,
  getMonthlyTrend,
  getResolutionTime
} = require('../controllers/dashboard.controller');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/role');

// All dashboard analytics routes require admin privileges
router.use(protect);
router.use(authorize('admin'));

router.get('/stats', getStats);
router.get('/by-category', getByCategory);
router.get('/by-status', getByStatus);
router.get('/monthly-trend', getMonthlyTrend);
router.get('/resolution-time', getResolutionTime);

module.exports = router;
