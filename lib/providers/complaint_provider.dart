import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/services/category_service.dart';

class ComplaintProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final CategoryService categoryService;

  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  ComplaintModel? _lastCreatedComplaint;

  ComplaintProvider({
    required this.apiClient,
    required this.categoryService,
  });

  List<CategoryModel> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isSubmitting => _isSubmitting;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;
  ComplaintModel? get lastCreatedComplaint => _lastCreatedComplaint;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await categoryService.getCategories();
      _isLoadingCategories = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoadingCategories = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? 'Failed to load categories';
      }
      notifyListeners();
    } catch (e) {
      _isLoadingCategories = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitComplaint({
    required String title,
    required String description,
    required String categoryId,
    required String location,
    String priority = 'Medium',
    bool isAnonymous = false,
    List<String> imagePaths = const [],
    void Function(int sent, int total)? onProgress,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _uploadProgress = 0.0;
    _lastCreatedComplaint = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'title': title.trim(),
        'description': description.trim(),
        'category': categoryId,
        'location': location.trim(),
        'priority': priority,
        'isAnonymous': isAnonymous ? 'true' : 'false',
      });

      for (final path in imagePaths) {
        final filename = path.split('/').last;
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              path,
              filename: filename.isNotEmpty ? filename : 'upload.jpg',
            ),
          ),
        );
      }

      debugPrint('[ComplaintProvider] Submitting complaint to /complaints...');
      final response = await apiClient.dio.post(
        '/complaints',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            onProgress?.call(sent, total);
            notifyListeners();
          }
        },
      );
      debugPrint('[ComplaintProvider] Response status: ${response.statusCode}');

      final resData = response.data as Map<String, dynamic>;
      final complaintData = resData['data'] is Map<String, dynamic>
          ? resData['data'] as Map<String, dynamic>
          : resData['complaint'] is Map<String, dynamic>
              ? resData['complaint'] as Map<String, dynamic>
              : resData;

      _lastCreatedComplaint = ComplaintModel.fromJson(complaintData);
      _isSubmitting = false;
      _uploadProgress = 1.0;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isSubmitting = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? 'Failed to submit complaint';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
