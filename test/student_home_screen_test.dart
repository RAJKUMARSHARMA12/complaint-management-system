import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/screens/student_home_screen.dart';
import 'package:major_project/services/category_service.dart';
import 'package:provider/provider.dart';

class FakeStorageService implements StorageService {
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'fake_jwt_token';
  @override
  Future<void> deleteToken() async {}
  @override
  Future<void> saveUserData(Map<String, dynamic> data) async {}
  @override
  Future<Map<String, dynamic>?> getUserData() async => null;
  @override
  Future<void> deleteUserData() async {}
  @override
  Future<void> clearAuth() async {}
}

class FakeCategoryService extends CategoryService {
  FakeCategoryService()
      : super(
          apiClient: ApiClient(storageService: FakeStorageService()),
        );

  @override
  Future<List<CategoryModel>> getCategories() async => [];
}

class FakeComplaintProvider extends ComplaintProvider {
  FakeComplaintProvider({List<ComplaintModel>? initialComplaints})
      : super(
          apiClient: ApiClient(storageService: FakeStorageService()),
          categoryService: FakeCategoryService(),
        ) {
    if (initialComplaints != null) {
      testComplaints = initialComplaints;
    }
  }

  List<ComplaintModel> testComplaints = [];
  bool refreshCalled = false;

  @override
  List<ComplaintModel> get myComplaints => testComplaints;

  @override
  List<ComplaintModel> get activeComplaints =>
      testComplaints.where((c) => ['Submitted', 'Assigned', 'In Progress'].contains(c.status)).toList();

  @override
  List<ComplaintModel> get resolvedComplaints =>
      testComplaints.where((c) => c.status == 'Resolved').toList();

  @override
  int get totalComplaintsCount => testComplaints.length;

  @override
  int get activeComplaintsCount => activeComplaints.length;

  @override
  int get resolvedComplaintsCount => resolvedComplaints.length;

  @override
  Future<void> fetchMyComplaints({bool refresh = false}) async {
    refreshCalled = true;
  }
}

void main() {
  Widget createTestWidget({
    required AuthProvider authProvider,
    required ComplaintProvider complaintProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ComplaintProvider>.value(value: complaintProvider),
      ],
      child: MaterialApp(
        routes: {
          '/new-complaint': (ctx) => const Scaffold(body: Text('New Complaint Screen')),
          '/my-complaints': (ctx) => const Scaffold(body: Text('My Complaints Screen')),
        },
        home: const StudentHomeScreen(),
      ),
    );
  }

  testWidgets('StudentHomeScreen renders welcome greeting, metric cards, and recent complaints', (tester) async {
    final authProvider = AuthProvider(
      apiClient: ApiClient(storageService: FakeStorageService()),
      storageService: FakeStorageService(),
    );

    // Seed mock logged in student
    authProvider.setTestUser(
      UserModel(
        id: 'u1',
        name: 'Aarav Mehta',
        email: 'aarav.mehta@college.edu',
        role: 'student',
        department: 'Computer Science & Engineering',
      ),
      'test_token',
    );

    final complaints = [
      ComplaintModel(
        id: 'c1',
        complaintId: 'CMP-0001',
        title: 'Broken Library Light',
        description: 'Light flickering on study table',
        categoryName: 'Electrical',
        location: 'Library 1st Floor',
        priority: 'High',
        status: 'In Progress',
        createdAt: DateTime(2026, 11, 2),
      ),
      ComplaintModel(
        id: 'c2',
        complaintId: 'CMP-0002',
        title: 'Water Cooler Issue',
        description: 'Water not cooling in hostel',
        categoryName: 'Hostel Maintenance',
        location: 'Hostel B',
        priority: 'Low',
        status: 'Resolved',
        createdAt: DateTime(2026, 11, 1),
      ),
    ];

    final complaintProvider = FakeComplaintProvider(initialComplaints: complaints);

    await tester.pumpWidget(
      createTestWidget(
        authProvider: authProvider,
        complaintProvider: complaintProvider,
      ),
    );
    await tester.pumpAndSettle();

    // Verify User Greeting & Department
    expect(find.text('Welcome back,'), findsOneWidget);
    expect(find.text('Aarav Mehta'), findsOneWidget);
    expect(find.textContaining('Computer Science & Engineering'), findsOneWidget);

    // Verify Metric summaries
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // Total count = 2
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2)); // Active count = 1, Resolved count = 1
    expect(find.text('Resolved'), findsNWidgets(2)); // Metric card label + ComplaintCard StatusChip

    // Verify Recent Grievance items
    expect(find.text('CMP-0001'), findsOneWidget);
    expect(find.text('Broken Library Light'), findsOneWidget);
    expect(find.text('CMP-0002'), findsOneWidget);
    expect(find.text('Water Cooler Issue'), findsOneWidget);

    // Tap "Raise New Complaint" CTA button
    await tester.tap(find.byKey(const Key('home_raise_complaint_cta')));
    await tester.pumpAndSettle();
    expect(find.text('New Complaint Screen'), findsOneWidget);
  });

  testWidgets('StudentHomeScreen renders empty state when no complaints exist', (tester) async {
    final authProvider = AuthProvider(
      apiClient: ApiClient(storageService: FakeStorageService()),
      storageService: FakeStorageService(),
    );

    authProvider.setTestUser(
      UserModel(
        id: 'u1',
        name: 'Priya Sharma',
        email: 'priya@college.edu',
        role: 'student',
      ),
      'token',
    );

    final complaintProvider = FakeComplaintProvider(initialComplaints: []);

    await tester.pumpWidget(
      createTestWidget(
        authProvider: authProvider,
        complaintProvider: complaintProvider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No complaints lodged yet'), findsOneWidget);
  });
}
