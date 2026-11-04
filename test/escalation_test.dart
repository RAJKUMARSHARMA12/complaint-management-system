import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/providers/notification_provider.dart';
import 'package:major_project/screens/complaint_detail_screen.dart';
import 'package:major_project/services/category_service.dart';
import 'package:major_project/widgets/complaint_card.dart';
import 'package:major_project/widgets/escalation_badge.dart';

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
  group('Day 16: Escalation Badge & UI Integration Tests', () {
    testWidgets('EscalationBadge renders pulsing animation and text without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EscalationBadge(),
            ),
          ),
        ),
      );

      expect(find.byType(EscalationBadge), findsOneWidget);
      expect(find.text('ESCALATED / OVERDUE'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Advance animation timer
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('EscalationBadge compact mode renders short OVERDUE badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EscalationBadge(isCompact: true),
            ),
          ),
        ),
      );

      expect(find.byType(EscalationBadge), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('ComplaintCard renders EscalationBadge when isEscalated is true', (tester) async {
      final escalatedComplaint = ComplaintModel(
        id: 'cmp1',
        complaintId: 'CMP-1001',
        title: 'Broken electrical socket sparking',
        description: 'Sparking socket in classroom 204 posing immediate safety hazard.',
        categoryName: 'Electrical',
        priority: 'Urgent',
        status: 'Assigned',
        isEscalated: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(complaint: escalatedComplaint),
          ),
        ),
      );

      expect(find.byType(EscalationBadge), findsOneWidget);
      expect(find.text('OVERDUE'), findsOneWidget);

      // Test regular non-escalated complaint does not show badge
      final normalComplaint = ComplaintModel(
        id: 'cmp2',
        complaintId: 'CMP-1002',
        title: 'Water filter maintenance',
        description: 'Routine maintenance of water filter.',
        categoryName: 'Water',
        priority: 'Low',
        status: 'Assigned',
        isEscalated: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(complaint: normalComplaint),
          ),
        ),
      );

      expect(find.byType(EscalationBadge), findsNothing);
    });

    testWidgets('ComplaintDetailScreen displays animated ESCALATED badge when complaint isEscalated is true', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      final apiClient = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );
      final categoryService = CategoryService(apiClient: apiClient);
      final complaintProvider = ComplaintProvider(
        apiClient: apiClient,
        categoryService: categoryService,
      );
      final authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: FakeStorageService(),
      );
      final notificationProvider = NotificationProvider(apiClient: apiClient);

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
            if (options.path == '/complaints/cmp123') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      '_id': 'cmp123',
                      'complaintId': 'CMP-1234',
                      'title': 'Overdue hostel wifi router down',
                      'description': 'Wifi in Block B has been offline for 5 consecutive days.',
                      'category': {'name': 'IT & Network'},
                      'location': 'Hostel Block B',
                      'priority': 'High',
                      'status': 'In Progress',
                      'isEscalated': true,
                      'images': [],
                      'remarks': [],
                      'dueDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
          ],
          child: const MaterialApp(
            home: ComplaintDetailScreen(complaintId: 'cmp123'),
          ),
        ),
      );

      // Pump a few frames to resolve future and render screen (infinite animation present)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ComplaintDetailScreen), findsOneWidget);
      expect(find.byType(EscalationBadge), findsOneWidget);
      expect(find.text('ESCALATED / OVERDUE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
