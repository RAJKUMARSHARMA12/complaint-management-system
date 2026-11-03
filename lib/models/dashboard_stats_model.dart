class DashboardStatsModel {
  final DashboardStats stats;
  final List<CategoryCount> categoryDistribution;
  final List<StatusCount> statusDistribution;
  final List<MonthlyCount> monthlyTrend;
  final List<MttrItem> resolutionTime;

  DashboardStatsModel({
    required this.stats,
    required this.categoryDistribution,
    required this.statusDistribution,
    required this.monthlyTrend,
    required this.resolutionTime,
  });

  /// Computed Resolution Rate percentage: (Resolved + Closed) / Total * 100
  double get resolutionRatePercentage {
    if (stats.totalComplaints == 0) return 0.0;
    final totalResolved = stats.resolvedComplaints + stats.closedComplaints;
    final rate = (totalResolved / stats.totalComplaints) * 100.0;
    return double.parse(rate.toStringAsFixed(1));
  }

  /// Overall Mean Time to Resolution in hours
  double get overallMttrHours {
    try {
      final overallItem = resolutionTime.firstWhere(
        (item) =>
            item.category.toLowerCase().contains('overall') ||
            item.category.toLowerCase().contains('average'),
      );
      return overallItem.avgHours;
    } catch (_) {
      if (resolutionTime.isNotEmpty) {
        final sum = resolutionTime.fold<double>(
          0.0,
          (prev, elem) => prev + elem.avgHours,
        );
        return double.parse((sum / resolutionTime.length).toStringAsFixed(1));
      }
      return 0.0;
    }
  }

  /// Overall Mean Time to Resolution formatted as days (e.g., "1.8 Days")
  String get overallMttrDaysString {
    final days = overallMttrHours / 24.0;
    return '${days.toStringAsFixed(1)} Days';
  }

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      categoryDistribution: (json['byCategory'] as List<dynamic>? ?? [])
          .map((e) => CategoryCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusDistribution: (json['byStatus'] as List<dynamic>? ?? [])
          .map((e) => StatusCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyTrend: (json['monthlyTrend'] as List<dynamic>? ?? [])
          .map((e) => MonthlyCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      resolutionTime: (json['resolutionTime'] as List<dynamic>? ?? [])
          .map((e) => MttrItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardStats {
  final int totalComplaints;
  final int openComplaints;
  final int resolvedComplaints;
  final int closedComplaints;
  final int escalatedComplaints;

  DashboardStats({
    required this.totalComplaints,
    required this.openComplaints,
    required this.resolvedComplaints,
    required this.closedComplaints,
    required this.escalatedComplaints,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalComplaints: json['totalComplaints'] as int? ?? 0,
      openComplaints: json['openComplaints'] as int? ?? 0,
      resolvedComplaints: json['resolvedComplaints'] as int? ?? 0,
      closedComplaints: json['closedComplaints'] as int? ?? 0,
      escalatedComplaints: json['escalatedComplaints'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalComplaints': totalComplaints,
        'openComplaints': openComplaints,
        'resolvedComplaints': resolvedComplaints,
        'closedComplaints': closedComplaints,
        'escalatedComplaints': escalatedComplaints,
      };
}

class CategoryCount {
  final String category;
  final int count;

  CategoryCount({
    required this.category,
    required this.count,
  });

  factory CategoryCount.fromJson(Map<String, dynamic> json) {
    return CategoryCount(
      category: json['category'] as String? ?? 'General',
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'count': count,
      };
}

class StatusCount {
  final String status;
  final int count;

  StatusCount({
    required this.status,
    required this.count,
  });

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      status: json['status'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'count': count,
      };
}

class MonthlyCount {
  final String month;
  final int count;

  MonthlyCount({
    required this.month,
    required this.count,
  });

  factory MonthlyCount.fromJson(Map<String, dynamic> json) {
    return MonthlyCount(
      month: json['month'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'count': count,
      };
}

class MttrItem {
  final String category;
  final double avgHours;

  MttrItem({
    required this.category,
    required this.avgHours,
  });

  factory MttrItem.fromJson(Map<String, dynamic> json) {
    return MttrItem(
      category: json['category'] as String? ?? 'General',
      avgHours: (json['avgHours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'avgHours': avgHours,
      };
}
