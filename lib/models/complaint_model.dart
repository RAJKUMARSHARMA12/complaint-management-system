class RemarkModel {
  final String id;
  final String role;
  final String text;
  final String? userName;
  final DateTime? createdAt;

  RemarkModel({
    required this.id,
    required this.role,
    required this.text,
    this.userName,
    this.createdAt,
  });

  factory RemarkModel.fromJson(Map<String, dynamic> json) {
    String? userName;
    if (json['user'] != null) {
      if (json['user'] is Map<String, dynamic>) {
        userName = json['user']['name'];
      } else {
        userName = json['user'].toString();
      }
    }

    return RemarkModel(
      id: json['id'] ?? json['_id'] ?? '',
      role: json['role'] ?? '',
      text: json['text'] ?? '',
      userName: userName,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      if (userName != null) 'user': {'name': userName},
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

class StatusHistoryItem {
  final String status;
  final String? remarks;
  final DateTime? timestamp;

  StatusHistoryItem({
    required this.status,
    this.remarks,
    this.timestamp,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      status: json['status'] ?? '',
      remarks: json['remarks'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (remarks != null) 'remarks': remarks,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}

class ComplaintFeedback {
  final int rating;
  final String? comments;
  final DateTime? submittedAt;

  ComplaintFeedback({
    required this.rating,
    this.comments,
    this.submittedAt,
  });

  factory ComplaintFeedback.fromJson(Map<String, dynamic> json) {
    return ComplaintFeedback(
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating'].toString()) ?? 0,
      comments: json['comment'] ?? json['comments'],
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (comments != null) 'comments': comments,
      if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
    };
  }
}

class ComplaintModel {
  final String id;
  final String complaintId;
  final String title;
  final String description;
  final String? categoryId;
  final String categoryName;
  final String? categoryDepartment;
  final String? location;
  final String priority;
  final bool isAnonymous;
  final List<String> images;
  final String status;
  final List<StatusHistoryItem> statusHistory;
  final List<RemarkModel> remarks;
  final ComplaintFeedback? feedback;
  final String? submittedByName;
  final String? assignedToName;
  final String? department;
  final DateTime? dueDate;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ComplaintModel({
    required this.id,
    required this.complaintId,
    required this.title,
    required this.description,
    this.categoryId,
    required this.categoryName,
    this.categoryDepartment,
    this.location,
    required this.priority,
    this.isAnonymous = false,
    this.images = const [],
    required this.status,
    this.statusHistory = const [],
    this.remarks = const [],
    this.feedback,
    this.submittedByName,
    this.assignedToName,
    this.department,
    this.dueDate,
    this.resolvedAt,
    this.closedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    String categoryName = '';
    String? categoryId;
    String? categoryDepartment;

    if (json['category'] != null) {
      if (json['category'] is Map<String, dynamic>) {
        final catMap = json['category'] as Map<String, dynamic>;
        categoryId = catMap['id'] ?? catMap['_id'];
        categoryName = catMap['name'] ?? '';
        categoryDepartment = catMap['department'];
      } else {
        categoryName = json['category'].toString();
      }
    }

    String? submittedByName;
    if (json['submittedBy'] != null) {
      if (json['submittedBy'] is Map<String, dynamic>) {
        submittedByName = json['submittedBy']['name'];
      } else {
        submittedByName = json['submittedBy'].toString();
      }
    }

    String? assignedToName;
    if (json['assignedTo'] != null) {
      if (json['assignedTo'] is Map<String, dynamic>) {
        assignedToName = json['assignedTo']['name'];
      } else {
        assignedToName = json['assignedTo'].toString();
      }
    }

    List<String> images = [];
    if (json['images'] is List) {
      images = (json['images'] as List).map((e) => e.toString()).toList();
    }

    List<StatusHistoryItem> statusHistory = [];
    if (json['statusHistory'] is List) {
      statusHistory = (json['statusHistory'] as List)
          .map((item) => StatusHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<RemarkModel> remarks = [];
    if (json['remarks'] is List) {
      remarks = (json['remarks'] as List)
          .map((item) => RemarkModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    ComplaintFeedback? feedback;
    if (json['feedback'] != null && json['feedback'] is Map<String, dynamic>) {
      feedback = ComplaintFeedback.fromJson(json['feedback'] as Map<String, dynamic>);
    }

    return ComplaintModel(
      id: json['id'] ?? json['_id'] ?? '',
      complaintId: json['complaintId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: categoryId,
      categoryName: categoryName,
      categoryDepartment: categoryDepartment,
      location: json['location'],
      priority: json['priority'] ?? 'Medium',
      isAnonymous: json['isAnonymous'] ?? false,
      images: images,
      status: json['status'] ?? 'Submitted',
      statusHistory: statusHistory,
      remarks: remarks,
      feedback: feedback,
      submittedByName: submittedByName,
      assignedToName: assignedToName,
      department: json['department'],
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  ComplaintModel copyWith({
    String? id,
    String? complaintId,
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    String? categoryDepartment,
    String? location,
    String? priority,
    bool? isAnonymous,
    List<String>? images,
    String? status,
    List<StatusHistoryItem>? statusHistory,
    List<RemarkModel>? remarks,
    ComplaintFeedback? feedback,
    String? submittedByName,
    String? assignedToName,
    String? department,
    DateTime? dueDate,
    DateTime? resolvedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryDepartment: categoryDepartment ?? this.categoryDepartment,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      images: images ?? this.images,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      remarks: remarks ?? this.remarks,
      feedback: feedback ?? this.feedback,
      submittedByName: submittedByName ?? this.submittedByName,
      assignedToName: assignedToName ?? this.assignedToName,
      department: department ?? this.department,
      dueDate: dueDate ?? this.dueDate,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaintId': complaintId,
      'title': title,
      'description': description,
      if (categoryId != null) 'categoryId': categoryId,
      'category': categoryName,
      if (location != null) 'location': location,
      'priority': priority,
      'isAnonymous': isAnonymous,
      'images': images,
      'status': status,
      'statusHistory': statusHistory.map((h) => h.toJson()).toList(),
      'remarks': remarks.map((r) => r.toJson()).toList(),
      if (feedback != null) 'feedback': feedback!.toJson(),
      if (department != null) 'department': department,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
