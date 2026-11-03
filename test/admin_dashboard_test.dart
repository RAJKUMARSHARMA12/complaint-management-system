import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/dashboard_stats_model.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/providers/admin_provider.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/providers/notification_provider.dart';
import 'package:major_project/screens/admin_dashboard_screen.dart';
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
  group('Day 15: DashboardStatsModel Serialization & Calculations', () {
    test('parses complete analytics json payload accurately', () {
      final statsJson = {
        'totalComplaints': 100,
        'openComplaints': 30,
        'resolvedComplaints': 40,
        'closedComplaints': 30,
        'escalatedComplaints': 5,
      };

      final byCategoryJson = [
        {'category': 'Hostel Maintenance', 'count': 45},
        {'category': 'Mess & Dining', 'count': 35},
        {'category': 'Lab & IT', 'count': 20},
      ];

      final byStatusJson = [
        {'status': 'Submitted', 'count': 10},
        {'status': 'Assigned', 'count': 10},
        {'status': 'In Progress', 'count': 10},
        {'status': 'Resolved', 'count': 40},
        {'status': 'Closed', 'count': 30},
      ];

      final trendJson = [
        {'month': 'Oct 2025', 'count': 15},
        {'month': 'Nov 2025', 'count': 20},
        {'month': 'Dec 2025', 'count': 25},
        {'month': 'Jan 2026', 'count': 18},
        {'month': 'Feb 2026', 'count': 22},
      ];

      final mttrJson = [
        {'category': 'Hostel Maintenance', 'avgHours': 32.5},
        {'category': 'Mess & Dining', 'avgHours': 14.2},
        {'category': 'Overall Average', 'avgHours': 26.4},
      ];

      final model = DashboardStatsModel(
        stats: DashboardStats.fromJson(statsJson),
        categoryDistribution: byCategoryJson
            .map((c) => CategoryCount.fromJson(c))
            .toList(),
        statusDistribution:
            byStatusJson.map((s) => StatusCount.fromJson(s)).toList(),
        monthlyTrend:
            trendJson.map((m) => MonthlyCount.fromJson(m)).toList(),
        resolutionTime: mttrJson.map((r) => MttrItem.fromJson(r)).toList(),
      );

      expect(model.stats.totalComplaints, 100);
      expect(model.stats.escalatedComplaints, 5);
      expect(model.categoryDistribution.length, 3);
      expect(model.categoryDistribution[0].category, 'Hostel Maintenance');
      expect(model.statusDistribution.length, 5);
      expect(model.monthlyTrend.length, 5);
      expect(model.resolutionTime.length, 3);

      // Computed properties
      expect(model.resolutionRatePercentage, 70.0); // (40+30)/100 * 100
      expect(model.overallMttrHours, 26.4);
      expect(model.overallMttrDaysString, '1.1 Days');
    });

    test('handles division by zero and empty payloads gracefully', () {
      final model = DashboardStatsModel(
        stats: DashboardStats(
          totalComplaints: 0,
          openComplaints: 0,
          resolvedComplaints: 0,
          closedComplaints: 0,
          escalatedComplaints: 0,
        ),
        categoryDistribution: [],
        statusDistribution: [],
        monthlyTrend: [],
        resolutionTime: [],
      );

      expect(model.resolutionRatePercentage, 0.0);
      expect(model.overallMttrHours, 0.0);
      expect(model.overallMttrDaysString, '0.0 Days');
    });
  });

  group('Day 15: AdminProvider Dashboard Analytics State & API', () {
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

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/dashboard/stats') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'totalComplaints': 50,
                      'openComplaints': 15,
                      'resolvedComplaints': 20,
                      'closedComplaints': 15,
                      'escalatedComplaints': 3,
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
                      {'category': 'Hostel Maintenance', 'count': 25},
                      {'category': 'Mess Food', 'count': 15},
                      {'category': 'Electrical', 'count': 10},
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
                      {'status': 'Submitted', 'count': 5},
                      {'status': 'Assigned', 'count': 5},
                      {'status': 'In Progress', 'count': 5},
                      {'status': 'Resolved', 'count': 20},
                      {'status': 'Closed', 'count': 15},
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
                      {'month': 'Nov 2025', 'count': 8},
                      {'month': 'Dec 2025', 'count': 12},
                      {'month': 'Jan 2026', 'count': 10},
                      {'month': 'Feb 2026', 'count': 20},
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
                      {'category': 'Hostel Maintenance', 'avgHours': 48.0},
                      {'category': 'Overall Average', 'avgHours': 36.0},
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

    test('fetchDashboardAnalytics populates dashboardData with all 5 datasets', () async {
      expect(adminProvider.dashboardData, isNull);
      await adminProvider.fetchDashboardAnalytics();

      expect(adminProvider.dashboardData, isNotNull);
      final data = adminProvider.dashboardData!;
      expect(data.stats.totalComplaints, 50);
      expect(data.stats.escalatedComplaints, 3);
      expect(data.categoryDistribution.length, 3);
      expect(data.statusDistribution.length, 5);
      expect(data.monthlyTrend.length, 4);
      expect(data.resolutionTime.length, 2);
      expect(data.overallMttrHours, 36.0);
    });
  });

  group('Day 15: AdminDashboardScreen UI & Charts Widget Tests', () {
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

      // Pre-seed dashboardData
      adminProvider.setTestDashboardData(
        DashboardStatsModel(
          stats: DashboardStats(
            totalComplaints: 148,
            openComplaints: 16,
            resolvedComplaints: 70,
            closedComplaints: 62,
            escalatedComplaints: 4,
          ),
          categoryDistribution: [
            CategoryCount(category: 'Hostel Maintenance', count: 62),
            CategoryCount(category: 'Mess & Dining', count: 42),
            CategoryCount(category: 'Lab & IT', count: 26),
            CategoryCount(category: 'Electrical', count: 18),
          ],
          statusDistribution: [
            StatusCount(status: 'Submitted', count: 6),
            StatusCount(status: 'Assigned', count: 5),
            StatusCount(status: 'In Progress', count: 5),
            StatusCount(status: 'Resolved', count: 70),
            StatusCount(status: 'Closed', count: 62),
          ],
          monthlyTrend: [
            MonthlyCount(month: 'Nov 2025', count: 20),
            MonthlyCount(month: 'Dec 2025', count: 35),
            MonthlyCount(month: 'Jan 2026', count: 45),
            MonthlyCount(month: 'Feb 2026', count: 48),
          ],
          resolutionTime: [
            MttrItem(category: 'Hostel Maintenance', avgHours: 38.0),
            MttrItem(category: 'Overall Average', avgHours: 43.2), // 1.8 Days
          ],
        ),
      );
    });

    Widget wrap(Widget screen) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
          ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: MaterialApp(
          routes: {
            '/admin-complaints': (context) => const Scaffold(body: Text('Admin Complaints Screen')),
            '/manage-categories': (context) => const Scaffold(body: Text('Manage Categories Screen')),
            '/manage-users': (context) => const Scaffold(body: Text('Manage Users Screen')),
          },
          home: screen,
        ),
      );
    }

    testWidgets('renders KPI cards, PieChart, BarChart, and LineChart with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      // Header checks
      expect(find.text('Executive Dashboard'), findsOneWidget);
      expect(find.text('Institution Overview'), findsOneWidget);

      // KPI Metric values
      expect(find.text('148'), findsOneWidget); // Total Logs
      expect(find.text('89.2%'), findsOneWidget); // Resolution Rate
      expect(find.text('1.8 Days'), findsOneWidget); // Mean TTR
      expect(find.text('4'), findsWidgets); // Escalated

      // fl_chart elements
      expect(find.byType(PieChart), findsOneWidget);

      await tester.scrollUntilVisible(find.byType(BarChart), 200);
      expect(find.byType(BarChart), findsOneWidget);

      await tester.scrollUntilVisible(find.byType(LineChart), 200);
      expect(find.byType(LineChart), findsOneWidget);

      // Quick Nav Buttons
      expect(find.text('Master Queue'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('quick navigation buttons route correctly', (tester) async {
      await tester.pumpWidget(wrap(const AdminDashboardScreen()));
      await tester.pumpAndSettle();

      // Tap Master Queue
      await tester.tap(find.text('Master Queue'));
      await tester.pumpAndSettle();
      expect(find.text('Admin Complaints Screen'), findsOneWidget);
    });
  });
}
