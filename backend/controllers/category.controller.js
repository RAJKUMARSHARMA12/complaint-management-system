const { validationResult } = require('express-validator');
const Category = require('../models/Category');

// @desc    Get all active categories
// @route   GET /api/categories
// @access  Protected (All authenticated users)
const getCategories = async (req, res, next) => {
  try {
    const categories = await Category.find({ isActive: true })
      .populate('defaultAuthority', 'name email role department')
      .sort({ name: 1 });

    const formatted = categories.map((cat) => ({
      id: cat._id,
      name: cat.name,
      description: cat.description,
      slaDays: cat.slaDays,
      icon: cat.icon,
      defaultAuthority: cat.defaultAuthority
        ? {
            id: cat.defaultAuthority._id,
            name: cat.defaultAuthority.name,
            email: cat.defaultAuthority.email
          }
        : null
    }));

    return res.status(200).json({
      success: true,
      data: formatted
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all categories including inactive (Admin only)
// @route   GET /api/categories/all
// @access  Protected (Admin only)
const getAllCategoriesAdmin = async (req, res, next) => {
  try {
    const categories = await Category.find()
      .populate('defaultAuthority', 'name email role department')
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: categories
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new category
// @route   POST /api/categories
// @access  Protected (Admin only)
const createCategory = async (req, res, next) => {
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

    const { name, description, defaultAuthority, slaDays, icon } = req.body;

    const existing = await Category.findOne({ name: name.trim() });
    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'A category with this name already exists.',
        errors: [{ field: 'name', message: 'Category name must be unique.' }]
      });
    }

    const category = await Category.create({
      name: name.trim(),
      description: description ? description.trim() : '',
      defaultAuthority: defaultAuthority || null,
      slaDays: slaDays || 3,
      icon: icon || 'help_outline',
      isActive: true
    });

    return res.status(201).json({
      success: true,
      message: 'Category created successfully',
      data: {
        id: category._id,
        name: category.name,
        description: category.description,
        slaDays: category.slaDays,
        icon: category.icon,
        isActive: category.isActive
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Toggle category active status
// @route   PATCH /api/categories/:id/status
// @access  Protected (Admin only)
const toggleCategoryStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isActive boolean field is required.'
      });
    }

    const category = await Category.findById(id);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: `Category not found with id: ${id}`
      });
    }

    category.isActive = isActive;
    await category.save();

    return res.status(200).json({
      success: true,
      message: 'Category status updated successfully',
      data: {
        id: category._id,
        name: category.name,
        isActive: category.isActive
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getCategories,
  getAllCategoriesAdmin,
  createCategory,
  toggleCategoryStatus
};
