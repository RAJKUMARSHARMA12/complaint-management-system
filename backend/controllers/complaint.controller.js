const { validationResult } = require('express-validator');
const Complaint = require('../models/Complaint');
const Category = require('../models/Category');
const Counter = require('../models/Counter');

// Atomic sequential ID generator helper (e.g. CMP-0001, CMP-0002)
const getNextComplaintId = async () => {
  const counter = await Counter.findByIdAndUpdate(
    { _id: 'complaintId' },
    { $inc: { seq: 1 } },
    { returnDocument: 'after', upsert: true }
  );
  const formattedNumber = String(counter.seq).padStart(4, '0');
  return `CMP-${formattedNumber}`;
};

// @desc    Submit new complaint (Multipart Upload)
// @route   POST /api/complaints
// @access  Protected (Student only)
const createComplaint = async (req, res, next) => {
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

    const {
      title,
      description,
      category: categoryId,
      location,
      priority,
      isAnonymous
    } = req.body;

    // Validate category existence
    const categoryDoc = await Category.findById(categoryId);
    if (!categoryDoc || !categoryDoc.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or inactive category selected.'
      });
    }

    // Generate atomic sequential ID
    const complaintId = await getNextComplaintId();

    // Process uploaded images
    const mediaBaseUrl = process.env.MEDIA_BASE_URL || 'http://localhost:8080/uploads';
    let images = [];
    if (req.files && req.files.length > 0) {
      images = req.files.map((file) => `${mediaBaseUrl}/${file.filename}`);
    }

    // Check if category has default authority configured for auto-routing
    let status = 'Submitted';
    let assignedTo = null;
    let dueDate = null;

    if (categoryDoc.defaultAuthority) {
      status = 'Assigned';
      assignedTo = categoryDoc.defaultAuthority;
      const slaDays = categoryDoc.slaDays || 3;
      dueDate = new Date(Date.now() + slaDays * 24 * 60 * 60 * 1000);
    }

    const complaint = await Complaint.create({
      complaintId,
      title: title.trim(),
      description: description.trim(),
      category: categoryDoc._id,
      location: location.trim(),
      priority: priority || 'Medium',
      isAnonymous: isAnonymous === 'true' || isAnonymous === true,
      images,
      createdBy: req.user._id,
      assignedTo,
      status,
      dueDate,
      remarks: [
        {
          user: req.user._id,
          role: req.user.role,
          text: `Grievance submitted by ${
            isAnonymous === 'true' || isAnonymous === true ? 'Anonymous Student' : req.user.name
          }.`
        }
      ]
    });

    return res.status(201).json({
      success: true,
      message: 'Complaint lodged successfully',
      data: {
        id: complaint._id,
        complaintId: complaint.complaintId,
        title: complaint.title,
        description: complaint.description,
        category: complaint.category,
        location: complaint.location,
        priority: complaint.priority,
        status: complaint.status,
        isAnonymous: complaint.isAnonymous,
        images: complaint.images,
        assignedTo: complaint.assignedTo,
        dueDate: complaint.dueDate,
        isEscalated: complaint.isEscalated,
        createdAt: complaint.createdAt
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current student's complaints with filtering & pagination
// @route   GET /api/complaints/my
// @access  Protected (Student only)
const getMyComplaints = async (req, res, next) => {
  try {
    const { status, page = 1, limit = 10 } = req.query;

    const query = { createdBy: req.user._id };
    if (status && status !== 'All') {
      query.status = status;
    }

    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 10;
    const skip = (pageNum - 1) * limitNum;

    const total = await Complaint.countDocuments(query);
    const complaints = await Complaint.find(query)
      .populate('category', 'name icon slaDays')
      .populate('assignedTo', 'name email department')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    const formatted = complaints.map((c) => ({
      id: c._id,
      complaintId: c.complaintId,
      title: c.title,
      description: c.description,
      category: c.category ? { id: c.category._id, name: c.category.name, icon: c.category.icon } : null,
      location: c.location,
      priority: c.priority,
      status: c.status,
      dueDate: c.dueDate,
      images: c.images,
      isEscalated: c.isEscalated,
      assignedTo: c.assignedTo ? { id: c.assignedTo._id, name: c.assignedTo.name } : null,
      createdAt: c.createdAt
    }));

    return res.status(200).json({
      success: true,
      data: {
        complaints: formatted,
        pagination: {
          total,
          page: pageNum,
          pages: Math.ceil(total / limitNum) || 1,
          limit: limitNum
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createComplaint,
  getMyComplaints
};
