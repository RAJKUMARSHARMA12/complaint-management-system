const express = require('express');
const { getUsers } = require('../controllers/user.controller');
const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/role');

const router = express.Router();

router.get('/', protect, authorize('admin'), getUsers);

module.exports = router;
