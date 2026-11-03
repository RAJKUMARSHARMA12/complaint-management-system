import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/providers/notification_provider.dart';
import 'package:major_project/screens/admin_all_complaints_screen.dart';
import 'package:major_project/services/category_service.dart';
import 'package:major_project/widgets/assign_authority_dialog.dart';

class FakeStorageService implements StorageService {
  String? token = 'fake_token';

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

class FakeCategoryService extends CategoryService {
  FakeCategoryService()
      : super(apiClient: ApiClient(storageService: FakeStorageService()));

  @override
  Future<List<CategoryModel>> getCategories() async => [
        CategoryModel(id: 'cat1', name: 'Hostel Maintenance', department: 'Hostel Maintenance'),
        CategoryModel(id: 'cat2', name: 'IT Services', department: 'IT Department'),
      ];
}

void main() {
  group('AdminAllComplaintsScreen Widget Tests (TDD)', () {
    late ApiClient apiClient;
    late Dio dio;
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
      complaintProvider = ComplaintProvider(
        apiClient: apiClient,
        categoryService: FakeCategoryService(),
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
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
        ],
        child: const MaterialApp(
          home: AdminAllComplaintsScreen(),
        ),
      );
    }

    testWidgets('renders search bar, filter chips, and complaint tickets', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
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
                          '_id': 'c1',
                          'complaintId': 'CMP-0001',
                          'title': 'Leaking Tap in Room 204',
                          'category': {'name': 'Hostel Maintenance'},
                          'status': 'Submitted',
                          'priority': 'High',
                          'isEscalated': false,
                          'createdAt': DateTime.now().toIso8601String(),
                        },
                        {
                          '_id': 'c2',
                          'complaintId': 'CMP-0002',
                          'title': 'Core Switch Failure',
                          'category': {'name': 'IT Services'},
                          'status': 'In Progress',
                          'priority': 'Urgent',
                          'isEscalated': true,
                          'assignedTo': {'name': 'Mr. Spark'},
                          'createdAt': DateTime.now().toIso8601String(),
                        },
                      ],
                    },
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
                          'id': 'auth1',
                          'name': 'Warden Sharma',
                          'email': 'warden@college.edu',
                          'role': 'authority',
                          'department': 'Hostel Maintenance',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/categories') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'categories': [],
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Master Console'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // search input
      expect(find.text('All'), findsWidgets); // Status filter chip
      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Escalated Only'), findsOneWidget);

      // Verify complaints displayed
      expect(find.text('CMP-0001'), findsOneWidget);
      expect(find.text('Leaking Tap in Room 204'), findsOneWidget);
      expect(find.text('CMP-0002'), findsOneWidget);
      expect(find.text('Core Switch Failure'), findsOneWidget);
      expect(find.text('ESCALATED'), findsOneWidget);
      expect(find.text('Assign'), findsOneWidget);
      expect(find.text('Reassign'), findsOneWidget);
    });

    testWidgets('tapping Assign button on submitted complaint opens AssignAuthorityDialog', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
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
                          '_id': 'c1',
                          'complaintId': 'CMP-0001',
                          'title': 'Leaking Tap in Room 204',
                          'category': {'name': 'Hostel Maintenance'},
                          'status': 'Submitted',
                          'priority': 'High',
                        },
                      ],
                    },
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
                          'id': 'auth1',
                          'name': 'Warden Sharma',
                          'email': 'warden@college.edu',
                          'role': 'authority',
                          'department': 'Hostel Maintenance',
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

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Assign
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      // AssignAuthorityDialog should be rendered
      expect(find.byType(AssignAuthorityDialog), findsOneWidget);
      expect(find.text('Assign Complaint'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AssignAuthorityDialog),
          matching: find.text('Leaking Tap in Room 204'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('filtering by Escalated Only sends query parameter and updates list', (tester) async {
      String? requestedEscalated;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/complaints') {
              requestedEscalated = options.queryParameters['isEscalated']?.toString();
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [
                        {
                          '_id': 'c2',
                          'complaintId': 'CMP-0002',
                          'title': 'Core Switch Failure',
                          'category': {'name': 'IT Services'},
                          'status': 'In Progress',
                          'priority': 'Urgent',
                          'isEscalated': true,
                        },
                      ],
                    },
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
                    'data': {'users': []},
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Ensure Escalated Only chip is scrolled into view and tap it
      await tester.ensureVisible(find.text('Escalated Only'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Escalated Only'));
      await tester.pumpAndSettle();

      expect(requestedEscalated, 'true');
      expect(find.text('CMP-0002'), findsOneWidget);
    });
  });
}
