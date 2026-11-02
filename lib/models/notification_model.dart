class NotificationModel {
  final String id;
  final String recipient;
  final String complaintId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.recipient,
    required this.complaintId,
    required this.title,
    required this.message,
    required this.type,
    this.read = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['_id'] ?? '',
      recipient: json['recipient'] is Map<String, dynamic>
          ? (json['recipient']['id'] ?? json['recipient']['_id'] ?? '')
          : json['recipient']?.toString() ?? '',
      complaintId: json['complaintId']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient': recipient,
      'complaintId': complaintId,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
