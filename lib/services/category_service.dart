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
}
