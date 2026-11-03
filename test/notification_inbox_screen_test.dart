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
import 'package:major_project/screens/notification_inbox_screen.dart';
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
  group('NotificationInboxScreen Widget Tests (TDD)', () {
    late ApiClient apiClient;
    late Dio dio;
    late NotificationProvider notificationProvider;
    late ComplaintProvider complaintProvider;
    late AuthProvider authProvider;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      apiClient = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );
      notificationProvider = NotificationProvider(apiClient: apiClient);
      complaintProvider = ComplaintProvider(
        apiClient: apiClient,
        categoryService: FakeCategoryService(),
      );
      authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: FakeStorageService(),
      );
      authProvider.setTestUser(
        UserModel(
          id: 'u1',
          name: 'Aarav Mehta',
          email: 'aarav@college.edu',
          role: 'student',
        ),
      );
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
          ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: NotificationInboxScreen(),
        ),
      );
    }

    testWidgets('renders empty inbox state when no notifications', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/notifications') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'unreadCount': 0,
                      'notifications': [],
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

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Your inbox is empty'), findsOneWidget);
    });

    testWidgets('displays list with unread dot indicators and marks all as read', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/notifications') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'unreadCount': 1,
                      'notifications': [
                        {
                          'id': 'notif-1',
                          'title': 'Complaint Assigned',
                          'message': 'Assigned to Officer Sharma',
                          'type': 'ASSIGNMENT',
                          'isRead': false,
                          'relatedComplaint': {
                            'id': 'cmp123',
                            'complaintId': 'CMP-2026-0001',
                            'title': 'Broken Tap',
                          },
                          'createdAt': DateTime.now().toIso8601String(),
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/notifications/read-all' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'All marked as read',
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

      expect(find.text('Complaint Assigned'), findsOneWidget);
      expect(find.text('Assigned to Officer Sharma'), findsOneWidget);
      expect(find.text('Ticket #CMP-2026-0001'), findsOneWidget);
      expect(find.byKey(const Key('unread_dot_notif-1')), findsOneWidget);
      expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);

      // Tap Mark All Read
      await tester.tap(find.byKey(const Key('mark_all_read_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('unread_dot_notif-1')), findsNothing);
      expect(find.byKey(const Key('mark_all_read_button')), findsNothing);
    });
  });
}
