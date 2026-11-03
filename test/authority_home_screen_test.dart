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
import 'package:major_project/screens/authority_home_screen.dart';
import 'package:major_project/services/category_service.dart';

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
  Future<List<CategoryModel>> getCategories() async => [];
}

void main() {
  group('AuthorityHomeScreen Widget Tests (TDD)', () {
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
          id: 'auth1',
          name: 'Warden Sharma',
          email: 'warden.hostel@college.edu',
          role: 'authority',
          department: 'Hostel Maintenance',
        ),
      );
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: AuthorityHomeScreen(),
        ),
      );
    }

    testWidgets('renders authority dashboard, department header, and KPI metrics', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/complaints/assigned') {
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
                          'complaintId': 'CMP-0001',
                          'title': 'Leaking Tap Block B',
                          'category': {'name': 'Hostel Maintenance'},
                          'priority': 'High',
                          'status': 'Assigned',
                          'dueDate': '2026-11-05T10:00:00.000Z',
                        },
                        {
                          '_id': 'cmp2',
                          'complaintId': 'CMP-0002',
                          'title': 'Corridor Light broken',
                          'category': {'name': 'Hostel Maintenance'},
                          'priority': 'Medium',
                          'status': 'In Progress',
                          'dueDate': '2026-11-06T10:00:00.000Z',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/notifications') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {'unreadCount': 0, 'notifications': []},
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Authority Console'), findsOneWidget);
      expect(find.text('Hello, Warden Sharma'), findsOneWidget);
      expect(find.text('Hostel Maintenance'), findsWidgets);

      // KPI Cards
      expect(find.text('Assigned'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Resolved'), findsWidgets);

      // Ticket list
      expect(find.text('CMP-0001'), findsOneWidget);
      expect(find.text('Leaking Tap Block B'), findsOneWidget);
      expect(find.byKey(const Key('update_status_btn_cmp1')), findsOneWidget);

      // Scroll to view second ticket if necessary
      await tester.scrollUntilVisible(
        find.text('CMP-0002'),
        50.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('CMP-0002'), findsOneWidget);
      expect(find.text('Corridor Light broken'), findsOneWidget);
    });

    testWidgets('taps Update button, opens StatusUpdateBottomSheet, and dispatches status update', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/complaints/assigned') {
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
                          'complaintId': 'CMP-0001',
                          'title': 'Leaking Tap Block B',
                          'category': {'name': 'Hostel Maintenance'},
                          'priority': 'High',
                          'status': 'Assigned',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/notifications') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {'unreadCount': 0, 'notifications': []},
                  },
                ),
              );
            }
            if (options.path == '/complaints/cmp1/status' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Status updated',
                    'data': {
                      'id': 'cmp1',
                      'complaintId': 'CMP-0001',
                      'status': 'In Progress',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('update_status_btn_cmp1')), findsOneWidget);

      // Tap update status button
      await tester.tap(find.byKey(const Key('update_status_btn_cmp1')));
      await tester.pumpAndSettle();

      expect(find.text('Update Ticket Status'), findsOneWidget);
      expect(find.byKey(const Key('transition_chip_In Progress')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('status_remark_field')),
        'Plumber has been dispatched with replacement pipe.',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('submit_status_button')));
      await tester.tap(find.byKey(const Key('submit_status_button')));
      await tester.pumpAndSettle();

      expect(find.text('Complaint status successfully updated!'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
    });
  });
}
