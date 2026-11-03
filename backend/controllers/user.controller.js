const { validationResult } = require('express-validator');
const User = require('../models/User');

// @desc    Get users list filtered by role (e.g. role=authority)
// @route   GET /api/users
// @access  Protected (Admin only)
const getUsers = async (req, res, next) => {
  try {
    const { role, department, isActive } = req.query;

    const query = {};
    if (role) {
      query.role = role.toLowerCase();
    }
    if (department) {
      query.department = department;
    }
    if (isActive !== undefined) {
      query.isActive = isActive === 'true' || isActive === true;
    }

    const users = await User.find(query)
      .select('name email role department phone isActive studentId createdAt')
      .sort({ name: 1 });

    return res.status(200).json({
      success: true,
      data: {
        users: users.map((u) => ({
          id: u._id,
          name: u.name,
          email: u.email,
          role: u.role,
          department: u.department,
          phone: u.phone,
          isActive: u.isActive,
          studentId: u.studentId,
          createdAt: u.createdAt
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new authority staff user (Admin only)
// @route   POST /api/users/authority
// @access  Protected (Admin only)
const createAuthority = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array().map((err) => ({
          field: err.path || err.param,
          message: err.msg
        }))
      });
    }

    const { name, email, password, department, phone } = req.body;

    const existingUser = await User.findOne({ email: email.toLowerCase().trim() });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email already exists.',
        errors: [{ field: 'email', message: 'Email must be unique.' }]
      });
    }

    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      role: 'authority',
      department: department ? department.trim() : '',
      phone: phone ? phone.trim() : undefined,
      isActive: true
    });

    return res.status(201).json({
      success: true,
      message: 'Authority account created successfully',
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department,
        phone: user.phone,
        isActive: user.isActive,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle user active status (Admin only)
// @route   PATCH /api/users/:id/status
// @access  Protected (Admin only)
const toggleUserStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isActive boolean field is required.'
      });
    }

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: `User not found with id: ${id}`
      });
    }

    // Prevent deactivating master admin
    if (user.role === 'admin' && !isActive) {
      return res.status(400).json({
        success: false,
        message: 'Cannot deactivate master admin account.'
      });
    }

    user.isActive = isActive;
    await user.save();

    return res.status(200).json({
      success: true,
      message: `User account ${isActive ? 'activated' : 'deactivated'} successfully`,
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        isActive: user.isActive
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getUsers,
  createAuthority,
  toggleUserStatus
};
