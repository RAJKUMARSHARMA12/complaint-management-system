import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/providers/admin_provider.dart';
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
  group('ManageUsersScreen Widget Tests (TDD)', () {
    late ApiClient apiClient;
    late Dio dio;
    late CategoryService categoryService;
    late AdminProvider adminProvider;

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
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
        ],
        child: const MaterialApp(
          home: ManageUsersScreen(),
        ),
      );
    }

    testWidgets('renders Authorities and Students tabs with user cards and switches', (tester) async {
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
                            'studentId': 'CS-2024-01',
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

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('User Governance'), findsOneWidget);
      expect(find.textContaining('Authorities'), findsOneWidget);
      expect(find.textContaining('Students'), findsOneWidget);

      // Verify Authority tab content
      expect(find.text('Warden Sharma'), findsOneWidget);
      expect(find.text('warden@college.edu'), findsOneWidget);
      expect(find.text('Hostel Maintenance'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Switch to Students tab
      await tester.tap(find.textContaining('Students'));
      await tester.pumpAndSettle();

      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('rahul@college.edu'), findsOneWidget);
      expect(find.text('ID: CS-2024-01'), findsOneWidget);
    });

    testWidgets('toggling user switch calls status update API', (tester) async {
      bool statusToggled = false;

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
                          'department': 'Hostel Maintenance',
                          'isActive': true,
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/users/auth1/status' && options.method == 'PATCH') {
              statusToggled = true;
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'User deactivated',
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

      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(statusToggled, isTrue);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    });

    testWidgets('tapping Add Authority opens dialog and creates authority staff', (tester) async {
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
                    'data': {'users': []},
                  },
                ),
              );
            }
            if (options.path == '/users/authority' && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'auth99',
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

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap FAB "+ Add Authority"
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Authority Staff'), findsOneWidget);

      // Enter form
      await tester.enterText(find.byKey(const Key('authority_name_field')), 'Coach David');
      await tester.enterText(find.byKey(const Key('authority_email_field')), 'coach@college.edu');
      await tester.enterText(find.byKey(const Key('authority_dept_field')), 'Sports Complex');
      await tester.enterText(find.byKey(const Key('authority_password_field')), 'CoachPassword@123');
      await tester.pumpAndSettle();

      // Tap Submit
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Dialog closed and Coach David is in list
      expect(find.text('Coach David'), findsOneWidget);
      expect(find.text('Sports Complex'), findsOneWidget);
    });
  });
}
