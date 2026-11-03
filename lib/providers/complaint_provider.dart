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

  ComplaintModel? _selectedComplaint;
  bool _isLoadingDetail = false;
  String? _detailError;
  bool _isPostingRemark = false;
  bool _isSubmittingFeedback = false;

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

  ComplaintModel? get selectedComplaint => _selectedComplaint;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;
  bool get isPostingRemark => _isPostingRemark;
  bool get isSubmittingFeedback => _isSubmittingFeedback;

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

  void setSelectedComplaint(ComplaintModel? complaint) {
    _selectedComplaint = complaint;
    _detailError = null;
    notifyListeners();
  }

  Future<void> fetchComplaintById(String id) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/complaints/$id');
      final resData = response.data as Map<String, dynamic>;

      Map<String, dynamic>? data;
      if (resData['data'] is Map<String, dynamic>) {
        data = resData['data'] as Map<String, dynamic>;
      } else if (resData['complaint'] is Map<String, dynamic>) {
        data = resData['complaint'] as Map<String, dynamic>;
      } else {
        data = resData;
      }

      _selectedComplaint = ComplaintModel.fromJson(data);
      
      // Also update in _myComplaints list if present
      final index = _myComplaints.indexWhere((c) => c.id == _selectedComplaint!.id || c.complaintId == _selectedComplaint!.complaintId);
      if (index != -1) {
        _myComplaints[index] = _selectedComplaint!;
      }

      _isLoadingDetail = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoadingDetail = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _detailError = e.response!.data['message'].toString();
      } else {
        _detailError = e.message ?? 'Failed to load complaint details';
      }
      notifyListeners();
    } catch (e) {
      _isLoadingDetail = false;
      _detailError = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addRemark({
    required String complaintId,
    required String text,
    String? userName,
    String? userRole,
  }) async {
    _isPostingRemark = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(
        '/complaints/$complaintId/remarks',
        data: {'text': text.trim()},
      );

      final resData = response.data as Map<String, dynamic>;
      List<RemarkModel> updatedRemarks = [];

      if (resData['data'] is Map && resData['data']['remarks'] is List) {
        final list = resData['data']['remarks'] as List<dynamic>;
        updatedRemarks = list
            .map((r) => RemarkModel.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      if (_selectedComplaint != null) {
        if (updatedRemarks.isNotEmpty) {
          // If the backend response returned remarks without populated user names, preserve what we know
          final combined = updatedRemarks.map((r) {
            if (r.userName == null && userName != null && (r.text == text.trim())) {
              return RemarkModel(
                id: r.id,
                role: r.role.isNotEmpty ? r.role : (userRole ?? 'student'),
                text: r.text,
                userName: userName,
                createdAt: r.createdAt ?? DateTime.now(),
              );
            }
            return r;
          }).toList();
          _selectedComplaint = _selectedComplaint!.copyWith(remarks: combined);
        } else {
          final newRemark = RemarkModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: userRole ?? 'student',
            text: text.trim(),
            userName: userName,
            createdAt: DateTime.now(),
          );
          _selectedComplaint = _selectedComplaint!.copyWith(
            remarks: [..._selectedComplaint!.remarks, newRemark],
          );
        }

        final index = _myComplaints.indexWhere((c) => c.id == _selectedComplaint!.id);
        if (index != -1) {
          _myComplaints[index] = _selectedComplaint!;
        }
      }

      _isPostingRemark = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isPostingRemark = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? 'Failed to add remark';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isPostingRemark = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitFeedback({
    required String complaintId,
    required int rating,
    String? comments,
  }) async {
    _isSubmittingFeedback = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(
        '/complaints/$complaintId/feedback',
        data: {
          'rating': rating,
          if (comments != null && comments.trim().isNotEmpty) 'comment': comments.trim(),
        },
      );

      final resData = response.data as Map<String, dynamic>;
      ComplaintFeedback? feedback;
      if (resData['data'] is Map && resData['data']['feedback'] is Map<String, dynamic>) {
        feedback = ComplaintFeedback.fromJson(resData['data']['feedback'] as Map<String, dynamic>);
      } else {
        feedback = ComplaintFeedback(
          rating: rating,
          comments: comments,
          submittedAt: DateTime.now(),
        );
      }

      if (_selectedComplaint != null) {
        _selectedComplaint = _selectedComplaint!.copyWith(
          status: 'Closed',
          feedback: feedback,
          closedAt: DateTime.now(),
        );

        final index = _myComplaints.indexWhere((c) => c.id == _selectedComplaint!.id || c.complaintId == _selectedComplaint!.complaintId);
        if (index != -1) {
          _myComplaints[index] = _selectedComplaint!;
        }
      }

      _isSubmittingFeedback = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isSubmittingFeedback = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? 'Failed to submit feedback';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmittingFeedback = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
