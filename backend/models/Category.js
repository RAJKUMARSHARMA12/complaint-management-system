const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Category name is required'],
      unique: true,
      trim: true,
      maxlength: [50, 'Category name cannot exceed 50 characters']
    },
    description: {
      type: String,
      trim: true,
      maxlength: [200, 'Description cannot exceed 200 characters']
    },
    defaultAuthority: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null
    },
    slaDays: {
      type: Number,
      required: [true, 'SLA turnaround days is required'],
      min: [1, 'SLA days must be at least 1'],
      max: [30, 'SLA days cannot exceed 30'],
      default: 3
    },
    icon: {
      type: String,
      default: 'help_outline'
    },
    isActive: {
      type: Boolean,
      default: true
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

// Indexes
categorySchema.index({ isActive: 1 });

module.exports = mongoose.model('Category', categorySchema);
