class NotificationModel {
  final String id;
  final String recipient;
  final String complaintId;
  final String? relatedComplaintMongoId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.recipient,
    required this.complaintId,
    this.relatedComplaintMongoId,
    required this.title,
    required this.message,
    required this.type,
    this.read = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String compId = '';
    String? mongoId;
    if (json['relatedComplaint'] != null) {
      if (json['relatedComplaint'] is Map<String, dynamic>) {
        final rc = json['relatedComplaint'] as Map<String, dynamic>;
        compId = rc['complaintId'] ?? rc['id'] ?? rc['_id'] ?? '';
        mongoId = rc['id'] ?? rc['_id'];
      } else {
        compId = json['relatedComplaint'].toString();
      }
    } else if (json['complaintId'] != null) {
      compId = json['complaintId'].toString();
    }

    final isRead = json['isRead'] ?? json['read'] ?? false;

    return NotificationModel(
      id: json['id'] ?? json['_id'] ?? '',
      recipient: json['recipient'] is Map<String, dynamic>
          ? (json['recipient']['id'] ?? json['recipient']['_id'] ?? '')
          : json['recipient']?.toString() ?? '',
      complaintId: compId,
      relatedComplaintMongoId: mongoId,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      read: isRead is bool ? isRead : (isRead.toString().toLowerCase() == 'true'),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? recipient,
    String? complaintId,
    String? relatedComplaintMongoId,
    String? title,
    String? message,
    String? type,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      complaintId: complaintId ?? this.complaintId,
      relatedComplaintMongoId: relatedComplaintMongoId ?? this.relatedComplaintMongoId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient': recipient,
      'complaintId': complaintId,
      if (relatedComplaintMongoId != null) 'relatedComplaintMongoId': relatedComplaintMongoId,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'isRead': read,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
