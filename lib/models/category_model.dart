class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String department;
  final int slaDays;
  final String? defaultAuthorityId;
  final String? defaultAuthorityName;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.department = '',
    this.slaDays = 3,
    this.defaultAuthorityId,
    this.defaultAuthorityName,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? authId;
    String? authName;

    if (json['defaultAuthority'] != null) {
      if (json['defaultAuthority'] is Map<String, dynamic>) {
        final authMap = json['defaultAuthority'] as Map<String, dynamic>;
        authId = authMap['id'] ?? authMap['_id']?.toString();
        authName = authMap['name']?.toString();
      } else {
        authId = json['defaultAuthority'].toString();
      }
    }

    return CategoryModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      department: json['department'] ?? '',
      slaDays: json['slaDays'] is int
          ? json['slaDays'] as int
          : int.tryParse(json['slaDays']?.toString() ?? '') ?? 3,
      defaultAuthorityId: authId,
      defaultAuthorityName: authName,
      isActive: json['isActive'] ?? true,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? department,
    int? slaDays,
    String? defaultAuthorityId,
    String? defaultAuthorityName,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      department: department ?? this.department,
      slaDays: slaDays ?? this.slaDays,
      defaultAuthorityId: defaultAuthorityId ?? this.defaultAuthorityId,
      defaultAuthorityName: defaultAuthorityName ?? this.defaultAuthorityName,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'department': department,
      'slaDays': slaDays,
      if (defaultAuthorityId != null)
        'defaultAuthority': {
          'id': defaultAuthorityId,
          if (defaultAuthorityName != null) 'name': defaultAuthorityName,
        },
      'isActive': isActive,
    };
  }
}
