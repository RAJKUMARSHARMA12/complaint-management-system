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

  List<ComplaintModel> _myComplaints = [];
  bool _isLoadingComplaints = false;
  String? _complaintsError;

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

  List<ComplaintModel> get myComplaints => _myComplaints;
  bool get isLoadingComplaints => _isLoadingComplaints;
  String? get complaintsError => _complaintsError;

  List<ComplaintModel> get activeComplaints =>
      _myComplaints.where((c) => ['Submitted', 'Assigned', 'In Progress'].contains(c.status)).toList();

  List<ComplaintModel> get resolvedComplaints =>
      _myComplaints.where((c) => c.status == 'Resolved').toList();

  List<ComplaintModel> get closedComplaints =>
      _myComplaints.where((c) => c.status == 'Closed').toList();

  int get totalComplaintsCount => _myComplaints.length;
  int get activeComplaintsCount => activeComplaints.length;
  int get resolvedComplaintsCount => resolvedComplaints.length;
  int get closedComplaintsCount => closedComplaints.length;

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
      _myComplaints.insert(0, _lastCreatedComplaint!);
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

  Future<void> fetchMyComplaints({bool refresh = false}) async {
    _isLoadingComplaints = true;
    _complaintsError = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/complaints/my');
      final resData = response.data as Map<String, dynamic>;

      List<dynamic> list = [];
      if (resData['data'] is Map && resData['data']['complaints'] is List) {
        list = resData['data']['complaints'] as List<dynamic>;
      } else if (resData['complaints'] is List) {
        list = resData['complaints'] as List<dynamic>;
      } else if (resData['data'] is List) {
        list = resData['data'] as List<dynamic>;
      }

      _myComplaints = list
          .map((item) => ComplaintModel.fromJson(item as Map<String, dynamic>))
          .toList();
      _isLoadingComplaints = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoadingComplaints = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _complaintsError = e.response!.data['message'].toString();
      } else {
        _complaintsError = e.message ?? 'Failed to load complaints';
      }
      notifyListeners();
    } catch (e) {
      _isLoadingComplaints = false;
      _complaintsError = e.toString();
      notifyListeners();
    }
  }
}
