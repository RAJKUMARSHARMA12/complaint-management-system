import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/providers/admin_provider.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/providers/notification_provider.dart';
import 'package:major_project/screens/admin_all_complaints_screen.dart';
import 'package:major_project/screens/manage_categories_screen.dart';
import 'package:major_project/screens/manage_users_screen.dart';
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
  group('UI Responsiveness & Compact Viewport Overflow Tests', () {
    late ApiClient apiClient;
    late Dio dio;
    late CategoryService categoryService;
    late AdminProvider adminProvider;
    late ComplaintProvider complaintProvider;
    late NotificationProvider notificationProvider;
    late AuthProvider authProvider;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      apiClient = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );
      categoryService = CategoryService(apiClient: apiClient);
      adminProvider = AdminProvider(
        apiClient: apiClient,
        categoryService: categoryService,
      );
      complaintProvider = ComplaintProvider(
        apiClient: apiClient,
        categoryService: categoryService,
      );
      notificationProvider = NotificationProvider(apiClient: apiClient);
      authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: FakeStorageService(),
      );
      authProvider.setTestUser(
        UserModel(
          id: 'admin1',
          name: 'Super Admin',
          email: 'admin@college.edu',
          role: 'admin',
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/categories/all' || options.path == '/categories') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        '_id': 'c1',
                        'name': 'Hostel Maintenance Department',
                        'description': 'Plumbing, electricity & mess',
                        'department': 'Hostel Department',
                        'slaDays': 3,
                        'isActive': true,
                      },
                    ],
                  },
                ),
              );
            }
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
                          'id': 'u1',
                          'name': 'Warden Sharma Very Long Name Example',
                          'email': 'warden.sharma.verylongemail@college.edu',
                          'role': 'authority',
                          'department': 'Hostel Maintenance & Civil Works Department',
                          'isActive': true,
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/complaints') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [
                        {
                          '_id': 'cmp1',
                          'complaintId': 'CMP-999999',
                          'title': 'Very Long Complaint Title Describing Water Leakage in Detail for Testing Overflow',
                          'category': {'name': 'Hostel Maintenance Department'},
                          'status': 'In Progress',
                          'priority': 'Urgent',
                          'isEscalated': true,
                          'assignedTo': {'name': 'Warden Sharma Very Long Name Example'},
                        },
                      ],
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );
    });

    Widget wrap(Widget screen, {double textScale = 1.0}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 640), // Compact mobile viewport
              textScaler: TextScaler.linear(textScale),
            ),
            child: screen,
          ),
        ),
      );
    }

    testWidgets('ManageCategoriesScreen renders on compact 360x640 with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(const ManageCategoriesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ManageCategoriesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ManageUsersScreen renders on compact 360x640 with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(const ManageUsersScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ManageUsersScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminAllComplaintsScreen renders on compact 360x640 with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(const AdminAllComplaintsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AdminAllComplaintsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
