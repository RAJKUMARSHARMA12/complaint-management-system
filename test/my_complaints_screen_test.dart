import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/screens/my_complaints_screen.dart';
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
  Future<String?> getToken() async => 'fake_token';
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

class TestMockComplaintProvider extends ComplaintProvider {
  int fetchCallCount = 0;

  TestMockComplaintProvider(List<ComplaintModel> mockComplaints)
      : super(
          apiClient: ApiClient(storageService: FakeStorageService()),
          categoryService: FakeCategoryService(),
        ) {
    mockList = mockComplaints;
  }

  List<ComplaintModel> mockList = [];

  @override
  List<ComplaintModel> get myComplaints => mockList;

  @override
  List<ComplaintModel> get activeComplaints =>
      mockList.where((c) => ['Submitted', 'Assigned', 'In Progress'].contains(c.status)).toList();

  @override
  List<ComplaintModel> get resolvedComplaints =>
      mockList.where((c) => c.status == 'Resolved').toList();

  @override
  List<ComplaintModel> get closedComplaints =>
      mockList.where((c) => c.status == 'Closed').toList();

  @override
  Future<void> fetchMyComplaints({bool refresh = false}) async {
    fetchCallCount++;
  }
}

void main() {
  Widget createScreen(ComplaintProvider provider) {
    return ChangeNotifierProvider<ComplaintProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: MyComplaintsScreen(),
      ),
    );
  }

  final testComplaints = [
    ComplaintModel(
      id: 'c1',
      complaintId: 'CMP-0001',
      title: 'Power Outage in Lab 3',
      description: 'Power cut in Computer Science building',
      categoryName: 'Electrical',
      location: 'Lab 3',
      priority: 'Urgent',
      status: 'Submitted',
      createdAt: DateTime(2026, 11, 2),
    ),
    ComplaintModel(
      id: 'c2',
      complaintId: 'CMP-0002',
      title: 'Water Tap Leaking',
      description: 'Tap broken in washroom',
      categoryName: 'Hostel Maintenance',
      location: 'Hostel 2',
      priority: 'High',
      status: 'Assigned',
      createdAt: DateTime(2026, 11, 2),
    ),
    ComplaintModel(
      id: 'c3',
      complaintId: 'CMP-0003',
      title: 'Mess Food Quality Issue',
      description: 'Cold dinner served',
      categoryName: 'Mess & Food',
      location: 'Mess Hall',
      priority: 'Medium',
      status: 'Resolved',
      createdAt: DateTime(2026, 11, 1),
    ),
    ComplaintModel(
      id: 'c4',
      complaintId: 'CMP-0004',
      title: 'Library AC not working',
      description: 'Hot in the study area',
      categoryName: 'Maintenance',
      location: 'Library',
      priority: 'Low',
      status: 'Closed',
      createdAt: DateTime(2026, 10, 28),
    ),
  ];

  testWidgets('MyComplaintsScreen displays all filter chips and switches views without extra network calls', (tester) async {
    final provider = TestMockComplaintProvider(testComplaints);

    await tester.pumpWidget(createScreen(provider));
    await tester.pumpAndSettle();

    final initialNetworkCalls = provider.fetchCallCount;

    // Verify filter chips exist
    expect(find.byKey(const Key('filter_chip_All')), findsOneWidget);
    expect(find.byKey(const Key('filter_chip_Active')), findsOneWidget);
    expect(find.byKey(const Key('filter_chip_Resolved')), findsOneWidget);
    expect(find.byKey(const Key('filter_chip_Closed')), findsOneWidget);

    // Initial state is "All" -> should see top items on screen
    expect(find.text('CMP-0001'), findsOneWidget);
    expect(find.text('CMP-0002'), findsOneWidget);

    // Tap "Active" filter chip
    await tester.tap(find.byKey(const Key('filter_chip_Active')));
    await tester.pumpAndSettle();

    // Verify instant client-side filtering without extra network requests
    expect(provider.fetchCallCount, equals(initialNetworkCalls));
    expect(find.text('CMP-0001'), findsOneWidget); // Submitted
    expect(find.text('CMP-0002'), findsOneWidget); // Assigned
    expect(find.text('CMP-0003'), findsNothing);   // Resolved filtered out
    expect(find.text('CMP-0004'), findsNothing);   // Closed filtered out

    // Tap "Resolved" filter chip
    await tester.tap(find.byKey(const Key('filter_chip_Resolved')));
    await tester.pumpAndSettle();

    expect(provider.fetchCallCount, equals(initialNetworkCalls));
    expect(find.text('CMP-0001'), findsNothing);
    expect(find.text('CMP-0002'), findsNothing);
    expect(find.text('CMP-0003'), findsOneWidget); // Resolved
    expect(find.text('CMP-0004'), findsNothing);

    // Tap "Closed" filter chip (scroll into view if needed)
    await tester.ensureVisible(find.byKey(const Key('filter_chip_Closed')));
    await tester.tap(find.byKey(const Key('filter_chip_Closed')));
    await tester.pumpAndSettle();

    expect(provider.fetchCallCount, equals(initialNetworkCalls));
    expect(find.text('CMP-0003'), findsNothing);
    expect(find.text('CMP-0004'), findsOneWidget); // Closed
  });

  testWidgets('MyComplaintsScreen displays empty state when filter has no complaints', (tester) async {
    // Only 1 complaint with status 'Submitted'
    final provider = TestMockComplaintProvider([
      ComplaintModel(
        id: 'c1',
        complaintId: 'CMP-0001',
        title: 'Light Problem',
        description: 'Light is broken in corridor',
        categoryName: 'Electrical',
        priority: 'Medium',
        status: 'Submitted',
        createdAt: DateTime(2026, 11, 2),
      ),
    ]);

    await tester.pumpWidget(createScreen(provider));
    await tester.pumpAndSettle();

    // Tap 'Resolved' filter chip where no items exist
    await tester.tap(find.byKey(const Key('filter_chip_Resolved')));
    await tester.pumpAndSettle();

    expect(find.text('No complaints found'), findsOneWidget);
  });
}
