import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final StorageService storageService;

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    required this.apiClient,
    required this.storageService,
  });

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _user != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      _token = token;
      _user = UserModel.fromJson(userData);

      await storageService.saveToken(token);
      await storageService.saveUserData(userData);

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? 'An unexpected network error occurred';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
        if (department != null && department.isNotEmpty)
          'department': department.trim(),
      };

      final response = await apiClient.post(
        '/auth/register',
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      _token = token;
      _user = UserModel.fromJson(userData);

      await storageService.saveToken(token);
      await storageService.saveUserData(userData);

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? 'Registration failed';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    final token = await storageService.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    _token = token;
    final cachedUserJson = await storageService.getUserData();
    if (cachedUserJson != null) {
      _user = UserModel.fromJson(cachedUserJson);
    }

    try {
      final response = await apiClient.get('/auth/me');
      final data = response.data as Map<String, dynamic>;
      if (data['user'] != null) {
        final userData = data['user'] as Map<String, dynamic>;
        _user = UserModel.fromJson(userData);
        await storageService.saveUserData(userData);
      }
      notifyListeners();
      return true;
    } catch (e) {
      // If token is invalid/expired (e.g. 401), storage is cleared by interceptor
      if (_user == null) {
        await logout();
        return false;
      }
      notifyListeners();
      return true;
    }
  }

  Future<void> logout() async {
    await storageService.clearAuth();
    _token = null;
    _user = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
