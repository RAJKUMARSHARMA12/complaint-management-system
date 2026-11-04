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
import 'package:major_project/screens/authority_home_screen.dart';
import 'package:major_project/screens/login_screen.dart';
import 'package:major_project/screens/manage_categories_screen.dart';
import 'package:major_project/screens/my_complaints_screen.dart';
import 'package:major_project/screens/new_complaint_screen.dart';
import 'package:major_project/services/category_service.dart';
import 'package:major_project/widgets/empty_state_view.dart';
import 'package:major_project/widgets/skeleton_loading.dart';

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

void main() {
  late ApiClient apiClient;
  late Dio dio;
  late FakeStorageService storage;
  late CategoryService categoryService;
  late AuthProvider authProvider;
  late ComplaintProvider complaintProvider;
  late AdminProvider adminProvider;
  late NotificationProvider notificationProvider;

  setUp(() {
    storage = FakeStorageService();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/categories')) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'data': {'categories': []},
                },
              ),
            );
          }
          if (options.path.contains('/complaints')) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'data': {'complaints': [], 'pagination': {'total': 0}},
                },
              ),
            );
          }
          if (options.path.contains('/users')) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'data': {'users': []},
                },
              ),
            );
          }
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'status': 'success', 'data': {}},
            ),
          );
        },
      ),
    );

    apiClient = ApiClient(
      storageService: storage,
      baseUrl: 'http://localhost:5001/api',
      customDio: dio,
    );

    categoryService = CategoryService(apiClient: apiClient);
    authProvider = AuthProvider(apiClient: apiClient, storageService: storage);
    authProvider.setTestUser(
      UserModel(
        id: 'user_day17',
        name: 'Alex Rivera',
        email: 'alex@campus.edu',
        role: 'student',
      ),
    );

    complaintProvider = ComplaintProvider(
      apiClient: apiClient,
      categoryService: categoryService,
    );

    adminProvider = AdminProvider(
      apiClient: apiClient,
      categoryService: categoryService,
    );

    notificationProvider = NotificationProvider(apiClient: apiClient);
  });

  Widget createTestApp(Widget child, {Size? size}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
        ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
        ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size ?? const Size(360, 640),
          ),
          child: child,
        ),
      ),
    );
  }

  group('Day 17 - Shimmer Skeleton Loading Tests', () {
    testWidgets('ShimmerBox and ComplaintCardSkeleton render and animate smoothly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: ComplaintListSkeleton(count: 3),
          ),
        ),
      );

      expect(find.byType(ComplaintCardSkeleton), findsNWidgets(3));
      expect(find.byType(ShimmerBox), findsWidgets);

      // Advance animation frames to verify repeat/dispose loop doesn't throw
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(tester.takeException(), isNull);
    });
  });

  group('Day 17 - EmptyStateView Tests', () {
    testWidgets('EmptyStateView renders title, message, and executes action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: EmptyStateView(
              icon: Icons.inbox_rounded,
              title: 'No Grievances Found',
              message: 'Try adjusting your search criteria.',
              actionLabel: 'Refresh Feed',
              onAction: () {
                actionTriggered = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('No Grievances Found'), findsOneWidget);
      expect(find.text('Try adjusting your search criteria.'), findsOneWidget);
      expect(find.text('Refresh Feed'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);

      await tester.tap(find.text('Refresh Feed'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('EmptyStateView without onAction hides action button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'Zero Results',
              message: 'No items match your filter.',
            ),
          ),
        ),
      );

      expect(find.text('Zero Results'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  group('Day 17 - Keyboard Tap-Outside Unfocus Tests', () {
    testWidgets('LoginScreen dismisses keyboard when tapping outside inputs', (tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('login_email_field'));
      expect(emailField, findsOneWidget);

      // Focus email field
      await tester.tap(emailField);
      await tester.pump();
      expect(FocusScope.of(tester.element(emailField)).hasFocus, isTrue);

      // Tap on background outside inputs
      await tester.tapAt(const Offset(20, 50));
      await tester.pump();

      // Keyboard should be unfocused
      final currentFocus = FocusManager.instance.primaryFocus;
      expect(currentFocus?.context?.widget is! EditableText, isTrue);
    });

    testWidgets('NewComplaintScreen dismisses keyboard when tapping outside inputs', (tester) async {
      await tester.pumpWidget(createTestApp(const NewComplaintScreen()));
      await tester.pumpAndSettle();

      final titleField = find.byKey(const Key('complaint_title_field'));
      expect(titleField, findsOneWidget);

      // Focus title field
      await tester.tap(titleField);
      await tester.pump();

      // Tap outside
      await tester.tapAt(const Offset(10, 100));
      await tester.pump();

      final currentFocus = FocusManager.instance.primaryFocus;
      expect(currentFocus?.context?.widget is! EditableText, isTrue);
    });

    testWidgets('MyComplaintsScreen search field unfocuses on tap outside', (tester) async {
      await tester.pumpWidget(createTestApp(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.tap(searchField);
      await tester.pump();

      // Tap below on the filter chip area or background
      await tester.tapAt(const Offset(20, 200));
      await tester.pump();

      final currentFocus = FocusManager.instance.primaryFocus;
      expect(currentFocus?.context?.widget is! EditableText, isTrue);
    });
  });

  group('Day 17 - Pull-To-Refresh Integrations', () {
    testWidgets('MyComplaintsScreen contains RefreshIndicator', (tester) async {
      await tester.pumpWidget(createTestApp(const MyComplaintsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('AuthorityHomeScreen contains RefreshIndicator', (tester) async {
      authProvider.setTestUser(
        UserModel(
          id: 'auth_user_1',
          name: 'Chief Proctor',
          email: 'proctor@campus.edu',
          role: 'authority',
          department: 'Hostel A',
        ),
      );

      await tester.pumpWidget(createTestApp(const AuthorityHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('AdminAllComplaintsScreen contains RefreshIndicator', (tester) async {
      authProvider.setTestUser(
        UserModel(
          id: 'admin_1',
          name: 'System Admin',
          email: 'admin@campus.edu',
          role: 'admin',
        ),
      );

      await tester.pumpWidget(createTestApp(const AdminAllComplaintsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('ManageCategoriesScreen contains RefreshIndicator', (tester) async {
      await tester.pumpWidget(createTestApp(const ManageCategoriesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('Day 17 - Compact Viewport Overflow Verification', () {
    testWidgets('Compact 360x640 mobile viewport displays empty states without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: EmptyStateView(
              icon: Icons.checklist_rounded,
              title: 'No Grievances in Queue',
              message:
                  'Every reported grievance assigned to your department has been successfully triaged and resolved.',
              actionLabel: 'Refresh Worklist',
            ),
          ),
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
