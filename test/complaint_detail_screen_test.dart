import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/services/category_service.dart';
import 'package:major_project/screens/complaint_detail_screen.dart';

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
  group('ComplaintDetailScreen Widget Tests (TDD)', () {
    late ApiClient apiClient;
    late Dio dio;
    late ComplaintProvider complaintProvider;
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
      authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: FakeStorageService(),
      );
      authProvider.setTestUser(
        UserModel(
          id: 'user1',
          name: 'Aarav Mehta',
          email: 'aarav@college.edu',
          role: 'student',
        ),
      );
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: ComplaintDetailScreen(complaintId: 'cmp123'),
        ),
      );
    }

    testWidgets('renders complaint detail, SLA, description, and empty remarks', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/complaints/cmp123')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      '_id': 'cmp123',
                      'complaintId': 'CMP-2026-0001',
                      'title': 'Leaking Tap in Block B',
                      'description': 'Continuous water drip in washroom 204',
                      'category': {'name': 'Hostel Maintenance'},
                      'location': 'Block B, 2nd Floor',
                      'priority': 'Medium',
                      'status': 'Submitted',
                      'dueDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
                      'remarks': [],
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

      expect(find.text('CMP-2026-0001'), findsWidgets);
      expect(find.text('Leaking Tap in Block B'), findsOneWidget);
      expect(find.text('Continuous water drip in washroom 204'), findsOneWidget);
      expect(find.text('Hostel Maintenance'), findsOneWidget);
      expect(find.text('Block B, 2nd Floor'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('No remarks posted yet.'), findsOneWidget);
      expect(find.byKey(const Key('remark_input_field')), findsOneWidget);
      expect(find.byKey(const Key('post_remark_button')), findsOneWidget);
    });

    testWidgets('submits remark and updates activity timeline list', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/complaints/cmp123')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      '_id': 'cmp123',
                      'complaintId': 'CMP-2026-0001',
                      'title': 'Leaking Tap in Block B',
                      'description': 'Continuous water drip in washroom 204',
                      'category': {'name': 'Hostel Maintenance'},
                      'priority': 'Medium',
                      'status': 'In Progress',
                      'remarks': [],
                    },
                  },
                ),
              );
            }
            if (options.path.contains('/complaints/cmp123/remarks')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'message': 'Remark added successfully',
                    'data': {
                      'remarks': [
                        {
                          'id': 'rem-101',
                          'role': 'student',
                          'text': 'Plumber hasn\'t arrived yet.',
                          'createdAt': DateTime.now().toIso8601String(),
                        }
                      ]
                    }
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

      expect(find.text('No remarks posted yet.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('remark_input_field')),
        'Plumber hasn\'t arrived yet.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('post_remark_button')));
      await tester.pumpAndSettle();

      expect(find.text('Plumber hasn\'t arrived yet.'), findsOneWidget);
      expect(find.text('No remarks posted yet.'), findsNothing);
    });

    testWidgets('shows Feedback Resolution card when status is Resolved and opens FeedbackDialog', (tester) async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/complaints/cmp123')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      '_id': 'cmp123',
                      'complaintId': 'CMP-2026-0001',
                      'title': 'Leaking Tap in Block B',
                      'description': 'Continuous water drip in washroom 204',
                      'category': {'name': 'Hostel Maintenance'},
                      'priority': 'Medium',
                      'status': 'Resolved',
                      'remarks': [],
                    },
                  },
                ),
              );
            }
            if (options.path.contains('/complaints/cmp123/feedback')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'status': 'Closed',
                      'feedback': {
                        'rating': 5,
                        'comments': 'Great work!',
                      }
                    }
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

      expect(find.text('Complaint Resolved!'), findsOneWidget);
      expect(find.byKey(const Key('rate_and_close_button')), findsOneWidget);

      // Tap Rate & Close Ticket button
      await tester.tap(find.byKey(const Key('rate_and_close_button')));
      await tester.pumpAndSettle();

      expect(find.text('Rate Resolution'), findsOneWidget);

      // Select 5 stars and submit
      await tester.tap(find.byKey(const Key('feedback_star_5')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      // Complaint status is now Closed
      expect(find.text('Rate Resolution'), findsNothing);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Student Feedback'), findsOneWidget);
    });
  });
}
