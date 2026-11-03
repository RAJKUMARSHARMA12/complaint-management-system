import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/providers/admin_provider.dart';
import 'package:major_project/services/category_service.dart';

class FakeStorageService implements StorageService {
  String? token = 'fake_admin_token';

  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<void> saveToken(String val) async => token = val;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> deleteToken() async => token = null;
  @override
  Future<void> saveUserData(Map<String, dynamic> data) async {}
  @override
  Future<Map<String, dynamic>?> getUserData() async => null;
  @override
  Future<void> deleteUserData() async {}
  @override
  Future<void> clearAuth() async => token = null;
}

void main() {
  group('AdminProvider Category & User Governance (TDD)', () {
    late ApiClient apiClient;
    late Dio dio;
    late CategoryService categoryService;
    late AdminProvider provider;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      apiClient = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );
      categoryService = CategoryService(apiClient: apiClient);
      provider = AdminProvider(
        apiClient: apiClient,
        categoryService: categoryService,
      );
    });

    test('fetchCategoriesAdmin loads all categories including inactive ones', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/categories/all') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        '_id': 'cat1',
                        'name': 'Hostel Maintenance',
                        'description': 'Plumbing and room issues',
                        'slaDays': 3,
                        'isActive': true,
                      },
                      {
                        '_id': 'cat2',
                        'name': 'Old Mess Service',
                        'description': 'Deprecated service',
                        'slaDays': 2,
                        'isActive': false,
                      },
                    ],
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      expect(provider.categories, isEmpty);
      await provider.fetchCategoriesAdmin();

      expect(provider.isLoadingCategories, isFalse);
      expect(provider.categories.length, 2);
      expect(provider.categories[0].name, 'Hostel Maintenance');
      expect(provider.categories[1].isActive, isFalse);
    });

    test('createCategory sends POST /categories and prepends to category list', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/categories' && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'cat3',
                      'name': 'Sports Complex',
                      'description': 'Courts and stadium',
                      'slaDays': 4,
                      'isActive': true,
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final success = await provider.createCategory(
        name: 'Sports Complex',
        description: 'Courts and stadium',
        slaDays: 4,
      );

      expect(success, isTrue);
      expect(provider.categories.length, 1);
      expect(provider.categories.first.name, 'Sports Complex');
      expect(provider.categories.first.slaDays, 4);
    });

    test('toggleCategoryStatus updates category active flag in-place', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/categories/all') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        '_id': 'cat1',
                        'name': 'Hostel Maintenance',
                        'isActive': true,
                      },
                    ],
                  },
                ),
              );
            }
            if (options.path == '/categories/cat1/status' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Category status updated successfully',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await provider.fetchCategoriesAdmin();
      expect(provider.categories.first.isActive, isTrue);

      final success = await provider.toggleCategoryStatus('cat1', false);
      expect(success, isTrue);
      expect(provider.categories.first.isActive, isFalse);
    });

    test('fetchUsers with role=authority and role=student populates respective lists', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/users') {
              final role = options.queryParameters['role'];
              if (role == 'authority') {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'success': true,
                      'data': {
                        'users': [
                          {
                            'id': 'auth1',
                            'name': 'Warden Sharma',
                            'email': 'warden@college.edu',
                            'role': 'authority',
                            'department': 'Hostel Maintenance',
                            'isActive': true,
                          },
                        ],
                      },
                    },
                  ),
                );
              } else if (role == 'student') {
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'success': true,
                      'data': {
                        'users': [
                          {
                            'id': 'stud1',
                            'name': 'Rahul Verma',
                            'email': 'rahul@college.edu',
                            'role': 'student',
                            'studentId': 'CS2024-001',
                            'isActive': true,
                          },
                        ],
                      },
                    },
                  ),
                );
              }
            }
            return handler.next(options);
          },
        ),
      );

      await provider.fetchUsers(role: 'authority');
      expect(provider.authorityUsers.length, 1);
      expect(provider.authorityUsers.first.name, 'Warden Sharma');

      await provider.fetchUsers(role: 'student');
      expect(provider.studentUsers.length, 1);
      expect(provider.studentUsers.first.name, 'Rahul Verma');
    });

    test('createAuthority sends POST /users/authority and appends to authorityUsers', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/users/authority' && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'auth2',
                      'name': 'Coach David',
                      'email': 'coach@college.edu',
                      'role': 'authority',
                      'department': 'Sports Complex',
                      'isActive': true,
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final success = await provider.createAuthority(
        name: 'Coach David',
        email: 'coach@college.edu',
        password: 'CoachPassword@123',
        department: 'Sports Complex',
      );

      expect(success, isTrue);
      expect(provider.authorityUsers.length, 1);
      expect(provider.authorityUsers.first.name, 'Coach David');
    });

    test('toggleUserStatus updates user isActive in-place', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/users') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'users': [
                        {
                          'id': 'auth1',
                          'name': 'Warden Sharma',
                          'email': 'warden@college.edu',
                          'role': 'authority',
                          'isActive': true,
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/users/auth1/status' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'User account deactivated successfully',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await provider.fetchUsers(role: 'authority');
      expect(provider.authorityUsers.first.isActive, isTrue);

      final success = await provider.toggleUserStatus(userId: 'auth1', isActive: false, role: 'authority');
      expect(success, isTrue);
      expect(provider.authorityUsers.first.isActive, isFalse);
    });
  });
}
