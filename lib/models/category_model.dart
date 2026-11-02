class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String department;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.department,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      department: json['department'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'department': department,
      'isActive': isActive,
    };
  }
}
