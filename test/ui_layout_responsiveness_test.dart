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
import 'package:major_project/screens/admin_dashboard_screen.dart';
import 'package:major_project/screens/complaint_detail_screen.dart';
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
            if (options.path == '/complaints/cmp1') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      '_id': 'cmp1',
                      'complaintId': 'CMP-999999',
                      'title': 'Very Long Complaint Title Describing Water Leakage in Detail for Testing Overflow',
                      'description': 'The pipe connected to water tank 4 on the terrace has burst, flooding the entire corridor on floor 3 and seeping through floorboards.',
                      'category': {'name': 'Hostel Maintenance Department'},
                      'location': 'Hostel Block 4, 3rd Floor East Wing Corridor',
                      'status': 'In Progress',
                      'priority': 'Urgent',
                      'isEscalated': true,
                      'images': [],
                      'remarks': [],
                      'dueDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
                      'assignedTo': {'name': 'Warden Sharma Very Long Name Example'},
                    },
                  },
                ),
              );
            }
            if (options.path == '/dashboard/stats') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'totalComplaints': 150,
                      'openComplaints': 25,
                      'resolvedComplaints': 75,
                      'closedComplaints': 50,
                      'escalatedComplaints': 6,
                    },
                  },
                ),
              );
            }
            if (options.path == '/dashboard/by-category') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {'category': 'Hostel & Residential Maintenance Very Long Name', 'count': 60},
                      {'category': 'Mess Dining & Food Quality', 'count': 40},
                      {'category': 'Electrical & Generator Infrastructure', 'count': 30},
                      {'category': 'Sanitation & Hygiene Services', 'count': 20},
                    ],
                  },
                ),
              );
            }
            if (options.path == '/dashboard/by-status') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {'status': 'Submitted', 'count': 10},
                      {'status': 'Assigned', 'count': 5},
                      {'status': 'In Progress', 'count': 10},
                      {'status': 'Resolved', 'count': 75},
                      {'status': 'Closed', 'count': 50},
                    ],
                  },
                ),
              );
            }
            if (options.path == '/dashboard/monthly-trend') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {'month': 'Oct 2025', 'count': 18},
                      {'month': 'Nov 2025', 'count': 22},
                      {'month': 'Dec 2025', 'count': 28},
                      {'month': 'Jan 2026', 'count': 34},
                      {'month': 'Feb 2026', 'count': 48},
                    ],
                  },
                ),
              );
            }
            if (options.path == '/dashboard/resolution-time') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {'category': 'Hostel Maintenance', 'avgHours': 42.5},
                      {'category': 'Mess Dining', 'avgHours': 18.2},
                      {'category': 'Overall Average', 'avgHours': 32.4},
                    ],
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

    testWidgets('AdminDashboardScreen renders on compact 360x640 with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminDashboardScreen renders on modern 390x844 with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ComplaintDetailScreen with EscalationBadge renders on compact 360x640 with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(const ComplaintDetailScreen(complaintId: 'cmp1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ComplaintDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
