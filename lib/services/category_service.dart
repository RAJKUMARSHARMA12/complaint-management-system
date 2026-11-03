import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/models/category_model.dart';

class CategoryService {
  final ApiClient apiClient;

  CategoryService({required this.apiClient});

  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.get('/categories');
    final resData = response.data as Map<String, dynamic>;

    List<dynamic> list = [];
    if (resData['data'] is List) {
      list = resData['data'] as List<dynamic>;
    } else if (resData['categories'] is List) {
      list = resData['categories'] as List<dynamic>;
    }

    return list
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryModel>> getAllCategoriesAdmin() async {
    final response = await apiClient.get('/categories/all');
    final resData = response.data as Map<String, dynamic>;

    List<dynamic> list = [];
    if (resData['data'] is List) {
      list = resData['data'] as List<dynamic>;
    } else if (resData['categories'] is List) {
      list = resData['categories'] as List<dynamic>;
    }

    return list
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    String? description,
    String? department,
    int slaDays = 3,
    String? defaultAuthority,
  }) async {
    final response = await apiClient.post(
      '/categories',
      data: {
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (department != null && department.trim().isNotEmpty)
          'department': department.trim(),
        'slaDays': slaDays,
        if (defaultAuthority != null && defaultAuthority.isNotEmpty)
          'defaultAuthority': defaultAuthority,
      },
    );

    final resData = response.data as Map<String, dynamic>;
    final itemData = resData['data'] is Map<String, dynamic>
        ? resData['data'] as Map<String, dynamic>
        : resData;

    return CategoryModel.fromJson(itemData);
  }

  Future<bool> toggleCategoryStatus(String id, bool isActive) async {
    final response = await apiClient.patch(
      '/categories/$id/status',
      data: {'isActive': isActive},
    );

    return response.statusCode == 200;
  }
}
