import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/models/dashboard_stats_model.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/services/category_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final CategoryService categoryService;

  // Dashboard Analytics State
  DashboardStatsModel? _dashboardData;
  bool _isLoadingDashboard = false;
  String? _dashboardError;

  // Category Governance State
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoryError;
  bool _isSavingCategory = false;

  // User Governance State
  List<UserModel> _authorityUsers = [];
  List<UserModel> _studentUsers = [];
  bool _isLoadingUsers = false;
  String? _userError;
  bool _isSavingUser = false;

  AdminProvider({
    required this.apiClient,
    required this.categoryService,
  });

  DashboardStatsModel? get dashboardData => _dashboardData;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get dashboardError => _dashboardError;

  List<CategoryModel> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoryError => _categoryError;
  bool get isSavingCategory => _isSavingCategory;

  List<UserModel> get authorityUsers => _authorityUsers;
  List<UserModel> get studentUsers => _studentUsers;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get userError => _userError;
  bool get isSavingUser => _isSavingUser;

  void clearErrors() {
    _dashboardError = null;
    _categoryError = null;
    _userError = null;
    notifyListeners();
  }

  void setTestDashboardData(DashboardStatsModel data) {
    _dashboardData = data;
    notifyListeners();
  }

  // ==================== Executive Dashboard Analytics ====================

  Future<void> fetchDashboardAnalytics() async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        apiClient.get('/dashboard/stats'),
        apiClient.get('/dashboard/by-category'),
        apiClient.get('/dashboard/by-status'),
        apiClient.get('/dashboard/monthly-trend'),
        apiClient.get('/dashboard/resolution-time'),
      ]);

      final statsRes = results[0].data as Map<String, dynamic>;
      final statsData = statsRes['data'] is Map<String, dynamic>
          ? statsRes['data'] as Map<String, dynamic>
          : statsRes;

      final catRes = results[1].data as Map<String, dynamic>;
      final categoryData = (catRes['data'] as List<dynamic>?) ?? [];

      final statusRes = results[2].data as Map<String, dynamic>;
      final statusData = (statusRes['data'] as List<dynamic>?) ?? [];

      final trendRes = results[3].data as Map<String, dynamic>;
      final trendData = (trendRes['data'] as List<dynamic>?) ?? [];

      final mttrRes = results[4].data as Map<String, dynamic>;
      final mttrData = (mttrRes['data'] as List<dynamic>?) ?? [];

      _dashboardData = DashboardStatsModel(
        stats: DashboardStats.fromJson(statsData),
        categoryDistribution: categoryData
            .map((c) => CategoryCount.fromJson(c as Map<String, dynamic>))
            .toList(),
        statusDistribution: statusData
            .map((s) => StatusCount.fromJson(s as Map<String, dynamic>))
            .toList(),
        monthlyTrend: trendData
            .map((m) => MonthlyCount.fromJson(m as Map<String, dynamic>))
            .toList(),
        resolutionTime: mttrData
            .map((r) => MttrItem.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

      _isLoadingDashboard = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoadingDashboard = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _dashboardError = e.response!.data['message'].toString();
      } else {
        _dashboardError = e.message ?? 'Failed to load dashboard analytics';
      }
      notifyListeners();
    } catch (e) {
      _isLoadingDashboard = false;
      _dashboardError = e.toString();
      notifyListeners();
    }
  }

  // ==================== Category Governance ====================

  Future<void> fetchCategoriesAdmin() async {
    _isLoadingCategories = true;
    _categoryError = null;
    notifyListeners();

    try {
      _categories = await categoryService.getAllCategoriesAdmin();
      _isLoadingCategories = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoadingCategories = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _categoryError = e.response!.data['message'].toString();
      } else {
        _categoryError = e.message ?? 'Failed to load categories';
      }
      notifyListeners();
    } catch (e) {
      _isLoadingCategories = false;
      _categoryError = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    String? description,
    String? department,
    int slaDays = 3,
    String? defaultAuthority,
  }) async {
    _isSavingCategory = true;
    _categoryError = null;
    notifyListeners();

    try {
      final newCategory = await categoryService.createCategory(
        name: name,
        description: description,
        department: department,
        slaDays: slaDays,
        defaultAuthority: defaultAuthority,
      );

      _categories.insert(0, newCategory);
      _isSavingCategory = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isSavingCategory = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _categoryError = e.response!.data['message'].toString();
      } else {
        _categoryError = e.message ?? 'Failed to create category';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isSavingCategory = false;
      _categoryError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleCategoryStatus(String categoryId, bool isActive) async {
    try {
      final success = await categoryService.toggleCategoryStatus(categoryId, isActive);
      if (success) {
        final index = _categories.indexWhere((c) => c.id == categoryId);
        if (index != -1) {
          _categories[index] = _categories[index].copyWith(isActive: isActive);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _categoryError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==================== User Governance ====================

  Future<void> fetchUsers({String? role}) async {
    _isLoadingUsers = true;
    _userError = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        if (role != null) 'role': role.toLowerCase(),
      };

      final response = await apiClient.get('/users', queryParameters: queryParams);
      final resData = response.data as Map<String, dynamic>;

      List<dynamic> list = [];
      if (resData['data'] is Map && resData['data']['users'] is List) {
        list = resData['data']['users'] as List<dynamic>;
      } else if (resData['users'] is List) {
        list = resData['users'] as List<dynamic>;
      } else if (resData['data'] is List) {
        list = resData['data'] as List<dynamic>;
      }

      final parsed = list
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (role?.toLowerCase() == 'authority') {
        _authorityUsers = parsed;
      } else if (role?.toLowerCase() == 'student') {
        _studentUsers = parsed;
      } else {
        _authorityUsers = parsed.where((u) => u.role.toLowerCase() == 'authority').toList();
        _studentUsers = parsed.where((u) => u.role.toLowerCase() == 'student').toList();
      }

      _isLoadingUsers = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoadingUsers = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _userError = e.response!.data['message'].toString();
      } else {
        _userError = e.message ?? 'Failed to load users';
      }
      notifyListeners();
    } catch (e) {
      _isLoadingUsers = false;
      _userError = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createAuthority({
    required String name,
    required String email,
    required String password,
    required String department,
    String? phone,
  }) async {
    _isSavingUser = true;
    _userError = null;
    notifyListeners();

    try {
      final response = await apiClient.post(
        '/users/authority',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'department': department.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );

      final resData = response.data as Map<String, dynamic>;
      final userData = resData['data'] is Map<String, dynamic>
          ? resData['data'] as Map<String, dynamic>
          : resData;

      final newUser = UserModel.fromJson(userData);
      _authorityUsers.insert(0, newUser);

      _isSavingUser = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isSavingUser = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _userError = e.response!.data['message'].toString();
      } else {
        _userError = e.message ?? 'Failed to create authority account';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isSavingUser = false;
      _userError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleUserStatus({
    required String userId,
    required bool isActive,
    required String role,
  }) async {
    try {
      final response = await apiClient.patch(
        '/users/$userId/status',
        data: {'isActive': isActive},
      );

      if (response.statusCode == 200) {
        if (role.toLowerCase() == 'authority') {
          final index = _authorityUsers.indexWhere((u) => u.id == userId);
          if (index != -1) {
            _authorityUsers[index] = _authorityUsers[index].copyWith(isActive: isActive);
            notifyListeners();
          }
        } else {
          final index = _studentUsers.indexWhere((u) => u.id == userId);
          if (index != -1) {
            _studentUsers[index] = _studentUsers[index].copyWith(isActive: isActive);
            notifyListeners();
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      _userError = e.toString();
      notifyListeners();
      return false;
    }
  }
}
