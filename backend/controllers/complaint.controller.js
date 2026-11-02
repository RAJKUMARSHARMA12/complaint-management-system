const { validationResult } = require('express-validator');
const Complaint = require('../models/Complaint');
const Category = require('../models/Category');
const Counter = require('../models/Counter');
const User = require('../models/User');
const { createNotification } = require('../utils/notify');

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

// Strict Finite State Machine transition rules
const STATUS_TRANSITIONS = {
  Submitted: ['Assigned'],
  Assigned: ['In Progress', 'Assigned'],
  'In Progress': ['Resolved'],
  Resolved: ['Closed', 'In Progress'],
  Closed: [] // Terminal state: immutable
};

// Whistleblower privacy helper
const scrubComplaint = (complaint, user) => {
  const compObj = complaint.toObject ? complaint.toObject() : { ...complaint };

  if (compObj._id && !compObj.id) {
    compObj.id = compObj._id;
  }

  // If complaint is anonymous and requester is NOT the original student owner
  const isOwner =
    user &&
    user.role === 'student' &&
    compObj.createdBy &&
    (compObj.createdBy._id || compObj.createdBy).toString() === user._id.toString();

  if (compObj.isAnonymous && !isOwner) {
    compObj.createdBy = {
      name: 'Anonymous Student',
      email: null,
      phone: null,
      studentId: null,
      department: null
    };
  }

  return compObj;
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

    const categoryDoc = await Category.findById(categoryId);
    if (!categoryDoc || !categoryDoc.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or inactive category selected.'
      });
    }

    const complaintId = await getNextComplaintId();

    const mediaBaseUrl = process.env.MEDIA_BASE_URL || 'http://localhost:8080/uploads';
    let images = [];
    if (req.files && req.files.length > 0) {
      images = req.files.map((file) => `${mediaBaseUrl}/${file.filename}`);
    }

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

    // Notification Hook: If complaint was auto-assigned upon creation
    if (assignedTo) {
      await createNotification({
        recipient: assignedTo,
        sender: req.user._id,
        title: 'New Complaint Assigned',
        message: `New ticket [${complaint.complaintId}] in '${categoryDoc.name}' assigned to your queue.`,
        type: 'ASSIGNMENT',
        relatedComplaint: complaint._id
      });
    }

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
      category: c.category
        ? { id: c.category._id, name: c.category.name, icon: c.category.icon }
        : null,
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

// @desc    Get complaints assigned to currently authenticated authority
// @route   GET /api/complaints/assigned
// @access  Protected (Authority only)
const getAssignedComplaints = async (req, res, next) => {
  try {
    const { status, priority, page = 1, limit = 10 } = req.query;

    const query = { assignedTo: req.user._id };
    if (status && status !== 'All') {
      query.status = status;
    }
    if (priority && priority !== 'All') {
      query.priority = priority;
    }

    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 10;
    const skip = (pageNum - 1) * limitNum;

    const total = await Complaint.countDocuments(query);
    const complaints = await Complaint.find(query)
      .populate('category', 'name icon slaDays')
      .populate('createdBy', 'name email phone studentId department')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    const formatted = complaints.map((c) => {
      const scrubbed = scrubComplaint(c, req.user);
      return {
        id: scrubbed.id || scrubbed._id,
        complaintId: scrubbed.complaintId,
        title: scrubbed.title,
        description: scrubbed.description,
        category: scrubbed.category
          ? { id: scrubbed.category._id, name: scrubbed.category.name, icon: scrubbed.category.icon }
          : null,
        location: scrubbed.location,
        priority: scrubbed.priority,
        status: scrubbed.status,
        dueDate: scrubbed.dueDate,
        images: scrubbed.images,
        isEscalated: scrubbed.isEscalated,
        isAnonymous: scrubbed.isAnonymous,
        createdBy: scrubbed.createdBy
          ? {
              name: scrubbed.createdBy.name,
              email: scrubbed.createdBy.email || null,
              phone: scrubbed.createdBy.phone || null
            }
          : null,
        createdAt: scrubbed.createdAt
      };
    });

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

// @desc    Admin Master Complaint Console with multi-faceted search & filter
// @route   GET /api/complaints
// @access  Protected (Admin only)
const getAllComplaintsAdmin = async (req, res, next) => {
  try {
    const {
      search,
      status,
      category,
      priority,
      isEscalated,
      page = 1,
      limit = 10
    } = req.query;

    const query = {};

    if (search && search.trim()) {
      const searchRegex = new RegExp(search.trim(), 'i');
      query.$or = [
        { complaintId: searchRegex },
        { title: searchRegex },
        { location: searchRegex }
      ];
    }

    if (status && status !== 'All') {
      query.status = status;
    }

    if (category && category !== 'All') {
      query.category = category;
    }

    if (priority && priority !== 'All') {
      query.priority = priority;
    }

    if (isEscalated !== undefined && isEscalated !== 'All') {
      query.isEscalated = isEscalated === 'true' || isEscalated === true;
    }

    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 10;
    const skip = (pageNum - 1) * limitNum;

    const total = await Complaint.countDocuments(query);
    const complaints = await Complaint.find(query)
      .populate('category', 'name icon slaDays')
      .populate('createdBy', 'name email phone studentId department')
      .populate('assignedTo', 'name email department')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    const formatted = complaints.map((c) => {
      const scrubbed = scrubComplaint(c, req.user);
      return {
        id: scrubbed.id || scrubbed._id,
        complaintId: scrubbed.complaintId,
        title: scrubbed.title,
        description: scrubbed.description,
        category: scrubbed.category
          ? { id: scrubbed.category._id, name: scrubbed.category.name, icon: scrubbed.category.icon }
          : null,
        assignedTo: scrubbed.assignedTo
          ? { id: scrubbed.assignedTo._id, name: scrubbed.assignedTo.name }
          : null,
        location: scrubbed.location,
        priority: scrubbed.priority,
        status: scrubbed.status,
        dueDate: scrubbed.dueDate,
        images: scrubbed.images,
        isEscalated: scrubbed.isEscalated,
        isAnonymous: scrubbed.isAnonymous,
        createdBy: scrubbed.createdBy
          ? {
              name: scrubbed.createdBy.name,
              email: scrubbed.createdBy.email || null,
              phone: scrubbed.createdBy.phone || null
            }
          : null,
        createdAt: scrubbed.createdAt
      };
    });

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

// @desc    Get detailed view of a single complaint (with whistleblower privacy scrubber)
// @route   GET /api/complaints/:id
// @access  Protected (Owner Student, Assigned Authority, or Admin)
const getComplaintById = async (req, res, next) => {
  try {
    const { id } = req.params;

    let complaint;
    // Allow lookup by Mongo _id OR by sequential complaintId (e.g. CMP-0001)
    if (id.startsWith('CMP-')) {
      complaint = await Complaint.findOne({ complaintId: id })
        .populate('category', 'name icon slaDays')
        .populate('createdBy', 'name email phone studentId department')
        .populate('assignedTo', 'name email department phone')
        .populate('remarks.user', 'name role department');
    } else {
      complaint = await Complaint.findById(id)
        .populate('category', 'name icon slaDays')
        .populate('createdBy', 'name email phone studentId department')
        .populate('assignedTo', 'name email department phone')
        .populate('remarks.user', 'name role department');
    }

    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: `Complaint not found with id: ${id}`
      });
    }

    // Role-based access authorization:
    // Only original student creator, assigned authority, or admin can inspect ticket details
    const isOwner =
      req.user.role === 'student' &&
      complaint.createdBy &&
      complaint.createdBy._id.toString() === req.user._id.toString();

    const isAssignedAuthority =
      req.user.role === 'authority' &&
      complaint.assignedTo &&
      complaint.assignedTo._id.toString() === req.user._id.toString();

    const isAdmin = req.user.role === 'admin';

    if (!isOwner && !isAssignedAuthority && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: You do not have permission to view this complaint.'
      });
    }

    const scrubbed = scrubComplaint(complaint, req.user);

    return res.status(200).json({
      success: true,
      data: {
        id: scrubbed.id || scrubbed._id,
        complaintId: scrubbed.complaintId,
        title: scrubbed.title,
        description: scrubbed.description,
        location: scrubbed.location,
        priority: scrubbed.priority,
        status: scrubbed.status,
        isAnonymous: scrubbed.isAnonymous,
        images: scrubbed.images,
        createdBy: scrubbed.createdBy
          ? {
              id: scrubbed.isAnonymous && !isOwner ? null : scrubbed.createdBy._id,
              name: scrubbed.createdBy.name,
              email: scrubbed.createdBy.email || null,
              phone: scrubbed.createdBy.phone || null,
              department: scrubbed.createdBy.department || null,
              studentId: scrubbed.createdBy.studentId || null
            }
          : null,
        assignedTo: scrubbed.assignedTo
          ? {
              id: scrubbed.assignedTo._id,
              name: scrubbed.assignedTo.name,
              email: scrubbed.assignedTo.email,
              department: scrubbed.assignedTo.department
            }
          : null,
        category: scrubbed.category
          ? {
              id: scrubbed.category._id,
              name: scrubbed.category.name,
              icon: scrubbed.category.icon,
              slaDays: scrubbed.category.slaDays
            }
          : null,
        dueDate: scrubbed.dueDate,
        resolvedAt: scrubbed.resolvedAt,
        closedAt: scrubbed.closedAt,
        isEscalated: scrubbed.isEscalated,
        escalatedAt: scrubbed.escalatedAt,
        remarks: (scrubbed.remarks || []).map((r) => ({
          id: r._id,
          role: r.role,
          text: r.text,
          user: r.user
            ? {
                name: r.user.name,
                role: r.user.role
              }
            : null,
          createdAt: r.createdAt
        })),
        feedback: scrubbed.feedback
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Assign or Reassign authority to complaint
// @route   PATCH /api/complaints/:id/assign
// @access  Protected (Admin only)
const assignComplaint = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { authorityId, remark } = req.body;

    if (!authorityId) {
      return res.status(400).json({
        success: false,
        message: 'authorityId is required.'
      });
    }

    const authorityUser = await User.findById(authorityId);
    if (!authorityUser || authorityUser.role !== 'authority' || !authorityUser.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Selected authorityId must belong to an active authority user.'
      });
    }

    const complaint = await Complaint.findById(id).populate('category');
    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: `Complaint not found with id: ${id}`
      });
    }

    if (complaint.status === 'Closed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot reassign a closed complaint.'
      });
    }

    // Update assignment and state
    complaint.assignedTo = authorityUser._id;
    complaint.status = 'Assigned';

    // Compute due date from Category SLA if present
    const slaDays = (complaint.category && complaint.category.slaDays) || 3;
    complaint.dueDate = new Date(Date.now() + slaDays * 24 * 60 * 60 * 1000);

    // Append audit remark
    const auditText = remark && remark.trim()
      ? `Reassigned to ${authorityUser.name}. Note: ${remark.trim()}`
      : `Complaint assigned to ${authorityUser.name}.`;

    complaint.remarks.push({
      user: req.user._id,
      role: req.user.role,
      text: auditText
    });

    await complaint.save();

    // Notification Hook: Alert newly assigned authority
    await createNotification({
      recipient: authorityUser._id,
      sender: req.user._id,
      title: 'Ticket Assigned to You',
      message: `Admin assigned complaint [${complaint.complaintId}] (${complaint.title}) to your department.`,
      type: 'ASSIGNMENT',
      relatedComplaint: complaint._id
    });

    // Also notify original student of the assignment
    await createNotification({
      recipient: complaint.createdBy,
      sender: req.user._id,
      title: 'Complaint Assigned',
      message: `Your complaint [${complaint.complaintId}] has been assigned to ${authorityUser.name}.`,
      type: 'ASSIGNMENT',
      relatedComplaint: complaint._id
    });

    return res.status(200).json({
      success: true,
      message: 'Complaint assigned successfully',
      data: {
        id: complaint._id,
        complaintId: complaint.complaintId,
        status: complaint.status,
        assignedTo: complaint.assignedTo,
        dueDate: complaint.dueDate
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update complaint status with strict FSM validation
// @route   PATCH /api/complaints/:id/status
// @access  Protected (Assigned Authority or Admin)
const updateComplaintStatus = async (req, res, next) => {
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

    const { id } = req.params;
    const { status: nextStatus, remark } = req.body;

    const complaint = await Complaint.findById(id);
    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: `Complaint not found with id: ${id}`
      });
    }

    // Role checks
    const isAdmin = req.user.role === 'admin';
    const isAssigned =
      req.user.role === 'authority' &&
      complaint.assignedTo &&
      complaint.assignedTo.toString() === req.user._id.toString();

    if (!isAdmin && !isAssigned) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: Only the assigned authority or an admin can update this complaint status.'
      });
    }

    // Validate legal state transition via FSM matrix
    const currentStatus = complaint.status;
    const allowedTransitions = STATUS_TRANSITIONS[currentStatus] || [];

    if (!allowedTransitions.includes(nextStatus)) {
      return res.status(400).json({
        success: false,
        message: `Invalid state transition from '${currentStatus}' to '${nextStatus}'. Allowed transitions: [${allowedTransitions.join(
          ', '
        )}]`
      });
    }

    // Mandatory remark check when marking Resolved
    if (nextStatus === 'Resolved') {
      if (!remark || remark.trim().length < 5) {
        return res.status(400).json({
          success: false,
          message: 'A descriptive action remark (min 5 characters) is required when marking a complaint Resolved.'
        });
      }
      complaint.resolvedAt = new Date();
    }

    complaint.status = nextStatus;

    if (remark && remark.trim()) {
      complaint.remarks.push({
        user: req.user._id,
        role: req.user.role,
        text: `Status changed to ${nextStatus}: ${remark.trim()}`
      });
    }

    await complaint.save();

    // Notification Hook: Alert student of status update
    await createNotification({
      recipient: complaint.createdBy,
      sender: req.user._id,
      title: 'Status Updated',
      message: `Your complaint [${complaint.complaintId}] status has been updated to '${nextStatus}'.`,
      type: 'STATUS_CHANGE',
      relatedComplaint: complaint._id
    });

    return res.status(200).json({
      success: true,
      message: 'Status updated successfully',
      data: {
        id: complaint._id,
        complaintId: complaint.complaintId,
        status: complaint.status,
        resolvedAt: complaint.resolvedAt
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add threaded collaborative remark to complaint
// @route   POST /api/complaints/:id/remarks
// @access  Protected (Owner Student, Assigned Authority, or Admin)
const addRemark = async (req, res, next) => {
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

    const { id } = req.params;
    const { text } = req.body;

    const complaint = await Complaint.findById(id);
    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: `Complaint not found with id: ${id}`
      });
    }

    if (complaint.status === 'Closed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot add remarks to a closed complaint.'
      });
    }

    // Role check
    const isOwner =
      req.user.role === 'student' &&
      complaint.createdBy.toString() === req.user._id.toString();
    const isAssigned =
      req.user.role === 'authority' &&
      complaint.assignedTo &&
      complaint.assignedTo.toString() === req.user._id.toString();
    const isAdmin = req.user.role === 'admin';

    if (!isOwner && !isAssigned && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: You are not authorized to post remarks to this complaint.'
      });
    }

    const newRemark = {
      user: req.user._id,
      role: req.user.role,
      text: text.trim(),
      createdAt: new Date()
    };

    complaint.remarks.push(newRemark);
    await complaint.save();

    // Notification Hook: Notify counter-party
    // If student posted remark -> notify assigned authority
    // If authority posted remark -> notify student creator
    let notifyRecipient = null;
    if (req.user.role === 'student' && complaint.assignedTo) {
      notifyRecipient = complaint.assignedTo;
    } else if (req.user.role === 'authority') {
      notifyRecipient = complaint.createdBy;
    }

    if (notifyRecipient) {
      await createNotification({
        recipient: notifyRecipient,
        sender: req.user._id,
        title: 'New Remark Added',
        message: `New note on [${complaint.complaintId}]: "${text.trim().substring(0, 60)}${text.length > 60 ? '...' : ''}"`,
        type: 'REMARK',
        relatedComplaint: complaint._id
      });
    }

    return res.status(201).json({
      success: true,
      message: 'Remark added successfully',
      data: {
        remarks: complaint.remarks.map((r) => ({
          id: r._id,
          role: r.role,
          text: r.text,
          createdAt: r.createdAt
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Submit feedback and formal closure for resolved complaint
// @route   POST /api/complaints/:id/feedback
// @access  Protected (Original student owner only)
const submitFeedback = async (req, res, next) => {
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

    const { id } = req.params;
    const { rating, comment } = req.body;

    const complaint = await Complaint.findById(id);
    if (!complaint) {
      return res.status(404).json({
        success: false,
        message: `Complaint not found with id: ${id}`
      });
    }

    // Constraint 1: Requester must be original creator
    if (complaint.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden: Only the original student who lodged this complaint can submit feedback.'
      });
    }

    // Constraint 2: Status must currently be strictly 'Resolved'
    if (complaint.status !== 'Resolved') {
      return res.status(400).json({
        success: false,
        message: `Feedback can only be submitted for complaints in 'Resolved' status. Current status: '${complaint.status}'.`
      });
    }

    // Constraint 3: Single feedback submission
    if (complaint.feedback && complaint.feedback.rating) {
      return res.status(400).json({
        success: false,
        message: 'Feedback has already been submitted for this complaint.'
      });
    }

    // Save feedback and transition to terminal Closed state
    complaint.feedback = {
      rating: Number(rating),
      comment: comment ? comment.trim() : '',
      submittedAt: new Date()
    };
    complaint.status = 'Closed';
    complaint.closedAt = new Date();

    complaint.remarks.push({
      user: req.user._id,
      role: req.user.role,
      text: `Complaint closed by student with ${rating}-star rating.${
        comment ? ` Review: "${comment.trim()}"` : ''
      }`
    });

    await complaint.save();

    // Notification Hook: Alert assigned authority of completion rating
    if (complaint.assignedTo) {
      await createNotification({
        recipient: complaint.assignedTo,
        sender: req.user._id,
        title: 'Feedback Received',
        message: `Student verified resolution for [${complaint.complaintId}] with a ${rating}-star rating. Ticket is now Closed.`,
        type: 'FEEDBACK',
        relatedComplaint: complaint._id
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Feedback submitted; complaint marked as Closed',
      data: {
        id: complaint._id,
        complaintId: complaint.complaintId,
        status: complaint.status,
        closedAt: complaint.closedAt,
        feedback: complaint.feedback
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createComplaint,
  getMyComplaints,
  getAssignedComplaints,
  getAllComplaintsAdmin,
  getComplaintById,
  assignComplaint,
  updateComplaintStatus,
  addRemark,
  submitFeedback
};
