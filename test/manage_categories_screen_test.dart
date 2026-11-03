import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/providers/admin_provider.dart';
import 'package:major_project/screens/manage_categories_screen.dart';
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
  group('ManageCategoriesScreen Widget Tests (TDD)', () {
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
          home: ManageCategoriesScreen(),
        ),
      );
    }

    testWidgets('renders category list with SLA badges and active toggles', (tester) async {
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
                        'description': 'Plumbing, electricity & mess',
                        'department': 'Hostel Department',
                        'slaDays': 3,
                        'isActive': true,
                      },
                      {
                        '_id': 'cat2',
                        'name': 'Old Transport',
                        'description': 'Legacy bus route',
                        'department': 'Transport Department',
                        'slaDays': 5,
                        'isActive': false,
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

      expect(find.text('Manage Categories'), findsOneWidget);
      expect(find.text('Hostel Maintenance'), findsOneWidget);
      expect(find.text('Plumbing, electricity & mess'), findsOneWidget);
      expect(find.text('SLA: 3 Days'), findsOneWidget);
      expect(find.text('Old Transport'), findsOneWidget);
      expect(find.text('SLA: 5 Days'), findsOneWidget);

      // Verify switches
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      expect(tester.widget<Switch>(switches.first).value, isTrue);
      expect(tester.widget<Switch>(switches.last).value, isFalse);
    });

    testWidgets('toggling category switch dispatches status update API', (tester) async {
      bool statusToggled = false;

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
                        'description': 'Plumbing issues',
                        'department': 'Hostel',
                        'slaDays': 3,
                        'isActive': true,
                      },
                    ],
                  },
                ),
              );
            }
            if (options.path == '/categories/cat1/status' && options.method == 'PATCH') {
              statusToggled = true;
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
            if (options.path == '/users') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'data': {'users': []}},
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

    testWidgets('tapping Add Category opens dialog and creates new category', (tester) async {
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
                    'data': [],
                  },
                ),
              );
            }
            if (options.path == '/categories' && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': {
                      'id': 'cat99',
                      'name': 'Sports Complex',
                      'description': 'Courts and gym',
                      'department': 'Sports',
                      'slaDays': 4,
                      'isActive': true,
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
                  data: {'success': true, 'data': {'users': []}},
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap floating action button to add category
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add New Category'), findsOneWidget);

      // Enter fields
      await tester.enterText(find.byKey(const Key('category_name_field')), 'Sports Complex');
      await tester.enterText(find.byKey(const Key('category_desc_field')), 'Courts and gym');
      await tester.enterText(find.byKey(const Key('category_dept_field')), 'Sports');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();

      // Dialog should close and new category should appear
      expect(find.text('Sports Complex'), findsOneWidget);
      expect(find.text('SLA: 4 Days'), findsOneWidget);
    });
  });
}
