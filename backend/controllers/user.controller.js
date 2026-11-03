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

module.exports = {
  getUsers
};
