const Complaint = require('../models/Complaint');
const Category = require('../models/Category');

/**
 * @desc    Get top-level KPI metrics
 * @route   GET /api/dashboard/stats
 * @access  Private (Admin only)
 */
exports.getStats = async (req, res, next) => {
  try {
    const totalComplaints = await Complaint.countDocuments();
    const openComplaints = await Complaint.countDocuments({
      status: { $in: ['Submitted', 'Assigned', 'In Progress'] }
    });
    const resolvedComplaints = await Complaint.countDocuments({
      status: 'Resolved'
    });
    const closedComplaints = await Complaint.countDocuments({
      status: 'Closed'
    });
    const escalatedComplaints = await Complaint.countDocuments({
      isEscalated: true
    });

    res.status(200).json({
      success: true,
      data: {
        totalComplaints,
        openComplaints,
        resolvedComplaints,
        closedComplaints,
        escalatedComplaints
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get breakdown of complaints by category
 * @route   GET /api/dashboard/by-category
 * @access  Private (Admin only)
 */
exports.getByCategory = async (req, res, next) => {
  try {
    const categoryStats = await Complaint.aggregate([
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 }
        }
      },
      {
        $lookup: {
          from: 'categories',
          localField: '_id',
          foreignField: '_id',
          as: 'categoryDoc'
        }
      },
      {
        $unwind: {
          path: '$categoryDoc',
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $project: {
          _id: 0,
          category: { $ifNull: ['$categoryDoc.name', 'Uncategorized'] },
          count: 1
        }
      },
      { $sort: { count: -1 } }
    ]);

    res.status(200).json({
      success: true,
      data: categoryStats
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get breakdown of complaints by status state
 * @route   GET /api/dashboard/by-status
 * @access  Private (Admin only)
 */
exports.getByStatus = async (req, res, next) => {
  try {
    const allStatuses = ['Submitted', 'Assigned', 'In Progress', 'Resolved', 'Closed'];

    const statusCounts = await Complaint.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]);

    const countMap = {};
    statusCounts.forEach((item) => {
      countMap[item._id] = item.count;
    });

    const result = allStatuses.map((st) => ({
      status: st,
      count: countMap[st] || 0
    }));

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get 6-month monthly complaint submission trend
 * @route   GET /api/dashboard/monthly-trend
 * @access  Private (Admin only)
 */
exports.getMonthlyTrend = async (req, res, next) => {
  try {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // Build timeline for last 6 months up to current month
    const timeline = [];
    const now = new Date();
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const label = `${monthNames[d.getMonth()]} ${d.getFullYear()}`;
      timeline.push({
        year: d.getFullYear(),
        monthNum: d.getMonth() + 1,
        month: label,
        count: 0
      });
    }

    const startDate = new Date(now.getFullYear(), now.getMonth() - 5, 1, 0, 0, 0);

    const trendAgg = await Complaint.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' }
          },
          count: { $sum: 1 }
        }
      }
    ]);

    const countMap = {};
    trendAgg.forEach((item) => {
      const key = `${item._id.year}-${item._id.month}`;
      countMap[key] = item.count;
    });

    const result = timeline.map((item) => {
      const key = `${item.year}-${item.monthNum}`;
      return {
        month: item.month,
        count: countMap[key] || 0
      };
    });

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @desc    Get Mean Time to Resolution (MTTR) by category and overall
 * @route   GET /api/dashboard/resolution-time
 * @access  Private (Admin only)
 */
exports.getResolutionTime = async (req, res, next) => {
  try {
    const categoryMttr = await Complaint.aggregate([
      {
        $match: {
          status: { $in: ['Resolved', 'Closed'] },
          $or: [{ resolvedAt: { $ne: null } }, { closedAt: { $ne: null } }]
        }
      },
      {
        $project: {
          category: 1,
          durationHours: {
            $divide: [
              {
                $subtract: [
                  { $ifNull: ['$resolvedAt', '$closedAt'] },
                  '$createdAt'
                ]
              },
              1000 * 60 * 60
            ]
          }
        }
      },
      {
        $group: {
          _id: '$category',
          avgHours: { $avg: '$durationHours' }
        }
      },
      {
        $lookup: {
          from: 'categories',
          localField: '_id',
          foreignField: '_id',
          as: 'categoryDoc'
        }
      },
      {
        $unwind: {
          path: '$categoryDoc',
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $project: {
          _id: 0,
          category: { $ifNull: ['$categoryDoc.name', 'General'] },
          avgHours: { $round: ['$avgHours', 1] }
        }
      },
      { $sort: { avgHours: -1 } }
    ]);

    const overallAgg = await Complaint.aggregate([
      {
        $match: {
          status: { $in: ['Resolved', 'Closed'] },
          $or: [{ resolvedAt: { $ne: null } }, { closedAt: { $ne: null } }]
        }
      },
      {
        $project: {
          durationHours: {
            $divide: [
              {
                $subtract: [
                  { $ifNull: ['$resolvedAt', '$closedAt'] },
                  '$createdAt'
                ]
              },
              1000 * 60 * 60
            ]
          }
        }
      },
      {
        $group: {
          _id: null,
          avgHours: { $avg: '$durationHours' }
        }
      }
    ]);

    const overallAvg =
      overallAgg.length > 0 && overallAgg[0].avgHours != null
        ? Math.round(overallAgg[0].avgHours * 10) / 10
        : 0.0;

    categoryMttr.push({
      category: 'Overall Average',
      avgHours: overallAvg
    });

    res.status(200).json({
      success: true,
      data: categoryMttr
    });
  } catch (error) {
    next(error);
  }
};
