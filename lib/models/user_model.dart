class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String? phone;
  final bool isActive;
  final String? studentId;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.phone,
    this.isActive = true,
    this.studentId,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Student',
      department: json['department'],
      phone: json['phone'],
      isActive: json['isActive'] ?? true,
      studentId: json['studentId'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? department,
    String? phone,
    bool? isActive,
    String? studentId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      studentId: studentId ?? this.studentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      if (department != null) 'department': department,
      if (phone != null) 'phone': phone,
      'isActive': isActive,
      if (studentId != null) 'studentId': studentId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
