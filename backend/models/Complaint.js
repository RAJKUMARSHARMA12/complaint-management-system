const mongoose = require('mongoose');

const remarkSubSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    role: {
      type: String,
      enum: ['student', 'authority', 'admin'],
      required: true
    },
    text: {
      type: String,
      required: true,
      trim: true,
      maxlength: [500, 'Remark cannot exceed 500 characters']
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  },
  { _id: true }
);

const feedbackSubSchema = new mongoose.Schema(
  {
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5
    },
    comment: {
      type: String,
      trim: true,
      maxlength: [300, 'Comment cannot exceed 300 characters']
    },
    submittedAt: {
      type: Date,
      default: Date.now
    }
  },
  { _id: false }
);

const complaintSchema = new mongoose.Schema(
  {
    complaintId: {
      type: String,
      unique: true,
      required: true
    },
    title: {
      type: String,
      required: [true, 'Title is required'],
      trim: true,
      minlength: [5, 'Title must be at least 5 characters long'],
      maxlength: [100, 'Title cannot exceed 100 characters']
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      trim: true,
      minlength: [20, 'Description must be at least 20 characters long'],
      maxlength: [1000, 'Description cannot exceed 1000 characters']
    },
    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: [true, 'Category is required']
    },
    location: {
      type: String,
      required: [true, 'Location details are required'],
      trim: true,
      maxlength: [100, 'Location cannot exceed 100 characters']
    },
    priority: {
      type: String,
      enum: {
        values: ['Low', 'Medium', 'High', 'Urgent'],
        message: 'Priority must be Low, Medium, High, or Urgent'
      },
      default: 'Medium'
    },
    images: [
      {
        type: String,
        trim: true
      }
    ],
    isAnonymous: {
      type: Boolean,
      default: false
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    },
    status: {
      type: String,
      enum: {
        values: ['Submitted', 'Assigned', 'In Progress', 'Resolved', 'Closed'],
        message: 'Invalid complaint status'
      },
      default: 'Submitted'
    },
    dueDate: {
      type: Date,
      default: null
    },
    resolvedAt: {
      type: Date,
      default: null
    },
    closedAt: {
      type: Date,
      default: null
    },
    isEscalated: {
      type: Boolean,
      default: false
    },
    escalatedAt: {
      type: Date,
      default: null
    },
    remarks: [remarkSubSchema],
    feedback: {
      type: feedbackSubSchema,
      default: null
    }
  },
  {
    timestamps: true,
    toJSON: {
      transform: function (doc, ret) {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      }
    }
  }
);

// Compound Indexes for fast queries & analytics
complaintSchema.index({ status: 1 });
complaintSchema.index({ category: 1 });
complaintSchema.index({ createdBy: 1 });
complaintSchema.index({ assignedTo: 1 });
complaintSchema.index({ isEscalated: 1 });
complaintSchema.index({ dueDate: 1 });
complaintSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Complaint', complaintSchema);
