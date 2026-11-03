import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/services/category_service.dart';

class FakeStorageService implements StorageService {
  String? token = 'lifecycle_mock_token';
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
  Future<List<CategoryModel>> getCategories() async => [
        CategoryModel(
          id: 'cat-civil',
          name: 'Civil Works & Road Repairs',
          department: 'Estate Maintenance',
          slaDays: 5,
          isActive: true,
        ),
      ];
}

void main() {
  group('Day 14: End-to-End Multi-Actor Lifecycle Integration Audit (Flutter)', () {
    late ApiClient apiClient;
    late Dio dio;
    late CategoryService categoryService;
    late ComplaintProvider complaintProvider;

    // In-memory complaint document simulation
    Map<String, dynamic> activeTicket = {
      '_id': 'ticket-101',
      'complaintId': 'CMP-101',
      'title': 'Cracked Pavement Outside Library',
      'description': 'Deep pavement fissure causing tripping hazard near library entrance',
      'category': {
        'id': 'cat-civil',
        'name': 'Civil Works & Road Repairs',
        'department': 'Estate Maintenance',
        'slaDays': 5,
      },
      'location': 'Central Library Walkway',
      'priority': 'High',
      'isAnonymous': false,
      'status': 'Submitted',
      'remarks': [],
      'statusHistory': [
        {
          'status': 'Submitted',
          'remarks': 'Complaint submitted by student',
          'timestamp': DateTime.now().toIso8601String(),
        }
      ],
      'images': ['https://res.cloudinary.com/demo/image/upload/sample.jpg'],
      'isEscalated': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      apiClient = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );
      categoryService = FakeCategoryService();
      complaintProvider = ComplaintProvider(
        apiClient: apiClient,
        categoryService: categoryService,
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Student Lodging
            if (options.path == '/complaints' && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': activeTicket,
                  },
                ),
              );
            }

            // Admin Query Master List
            if (options.path == '/complaints' && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [activeTicket],
                    },
                  },
                ),
              );
            }

            // Admin Query Staff
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
                          'id': 'warden1',
                          'name': 'Warden Sharma',
                          'email': 'warden@college.edu',
                          'role': 'authority',
                          'department': 'Estate Maintenance',
                          'isActive': true,
                        },
                      ],
                    },
                  },
                ),
              );
            }

            // Admin Delegates Ticket
            if (options.path == '/complaints/ticket-101/assign' && options.method == 'PATCH') {
              activeTicket['status'] = 'Assigned';
              activeTicket['assignedTo'] = {
                'id': 'warden1',
                'name': 'Warden Sharma',
                'department': 'Estate Maintenance',
              };
              activeTicket['dueDate'] = DateTime.now().add(const Duration(days: 5)).toIso8601String();
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Assigned successfully',
                    'data': activeTicket,
                  },
                ),
              );
            }

            // Authority Queue
            if (options.path == '/complaints/assigned' && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [activeTicket],
                    },
                  },
                ),
              );
            }

            // Status Transitions
            if (options.path == '/complaints/ticket-101/status' && options.method == 'PATCH') {
              final newStatus = options.data['status'];
              final remark = options.data['remark'];

              activeTicket['status'] = newStatus;
              if (newStatus == 'Resolved') {
                activeTicket['resolvedAt'] = DateTime.now().toIso8601String();
              }
              if (remark != null) {
                (activeTicket['remarks'] as List).add({
                  'id': 'rem-${DateTime.now().millisecondsSinceEpoch}',
                  'role': 'authority',
                  'text': remark,
                  'user': {'name': 'Warden Sharma'},
                  'createdAt': DateTime.now().toIso8601String(),
                });
              }

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': activeTicket,
                  },
                ),
              );
            }

            // Remark Append
            if (options.path == '/complaints/ticket-101/remarks' && options.method == 'POST') {
              final text = options.data['text'];
              (activeTicket['remarks'] as List).add({
                'id': 'rem-${DateTime.now().millisecondsSinceEpoch}',
                'role': 'authority',
                'text': text,
                'user': {'name': 'Warden Sharma'},
                'createdAt': DateTime.now().toIso8601String(),
              });

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'success': true,
                    'data': {
                      'remarks': activeTicket['remarks'],
                    },
                  },
                ),
              );
            }

            // Student Single Ticket Inspection
            if (options.path == '/complaints/ticket-101' && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': activeTicket,
                  },
                ),
              );
            }

            // Student Feedback & Closure
            if (options.path == '/complaints/ticket-101/feedback' && options.method == 'POST') {
              activeTicket['status'] = 'Closed';
              activeTicket['closedAt'] = DateTime.now().toIso8601String();
              activeTicket['feedback'] = {
                'rating': options.data['rating'],
                'comment': options.data['comment'],
                'submittedAt': DateTime.now().toIso8601String(),
              };

              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': activeTicket,
                  },
                ),
              );
            }

            return handler.next(options);
          },
        ),
      );
    });

    test('Full 4-Step Lifecycle: Student Lodge -> Admin Delegate -> Authority Resolve -> Student Rate & Close', () async {
      // ==========================================
      // STEP 1: Student lodges issue
      // ==========================================
      final lodgeSuccess = await complaintProvider.submitComplaint(
        title: 'Cracked Pavement Outside Library',
        description: 'Deep pavement fissure causing tripping hazard near library entrance',
        categoryId: 'cat-civil',
        location: 'Central Library Walkway',
        priority: 'High',
      );

      expect(lodgeSuccess, isTrue, reason: 'Student should successfully lodge complaint');
      expect(complaintProvider.lastCreatedComplaint, isNotNull);
      expect(complaintProvider.lastCreatedComplaint!.status, 'Submitted');
      expect(complaintProvider.lastCreatedComplaint!.complaintId, 'CMP-101');

      // ==========================================
      // STEP 2: Admin reviews & delegates to Authority
      // ==========================================
      await complaintProvider.fetchAllComplaintsAdmin();
      expect(complaintProvider.adminComplaints.length, 1);
      expect(complaintProvider.adminComplaints.first.status, 'Submitted');

      await complaintProvider.fetchAuthorityStaff();
      expect(complaintProvider.authorityStaff.isNotEmpty, isTrue);

      final delegateSuccess = await complaintProvider.assignComplaint(
        complaintId: 'ticket-101',
        authorityId: 'warden1',
        authorityName: 'Warden Sharma',
        remark: 'Please inspect and repair walkway promptly',
      );

      expect(delegateSuccess, isTrue, reason: 'Admin delegates complaint to Warden');
      expect(complaintProvider.adminComplaints.first.status, 'Assigned');
      expect(complaintProvider.adminComplaints.first.assignedToName, 'Warden Sharma');

      // ==========================================
      // STEP 3: Authority executes In Progress -> Remarks -> Resolved
      // ==========================================
      await complaintProvider.fetchAssignedComplaints();
      expect(complaintProvider.assignedComplaints.length, 1);
      expect(complaintProvider.assignedComplaints.first.status, 'Assigned');

      // Transition to In Progress
      final inProgressSuccess = await complaintProvider.updateComplaintStatus(
        complaintId: 'ticket-101',
        nextStatus: 'In Progress',
        remark: 'Masonry staff dispatched with repair materials',
      );
      expect(inProgressSuccess, isTrue);
      expect(complaintProvider.assignedComplaints.first.status, 'In Progress');

      // Add operational remark
      final remarkSuccess = await complaintProvider.addRemark(
        complaintId: 'ticket-101',
        text: 'Mortar filling finished. Safety barricade placed.',
        userName: 'Warden Sharma',
        userRole: 'authority',
      );
      expect(remarkSuccess, isTrue);

      // Transition to Resolved
      final resolvedSuccess = await complaintProvider.updateComplaintStatus(
        complaintId: 'ticket-101',
        nextStatus: 'Resolved',
        remark: 'Walkway restored, leveling verified.',
      );
      expect(resolvedSuccess, isTrue);
      expect(complaintProvider.assignedComplaints.first.status, 'Resolved');

      // ==========================================
      // STEP 4: Student reviews and submits 5-star feedback
      // ==========================================
      await complaintProvider.fetchComplaintById('ticket-101');
      expect(complaintProvider.selectedComplaint, isNotNull);
      expect(complaintProvider.selectedComplaint!.status, 'Resolved');
      expect(complaintProvider.selectedComplaint!.remarks.length, greaterThanOrEqualTo(2));

      final feedbackSuccess = await complaintProvider.submitFeedback(
        complaintId: 'ticket-101',
        rating: 5,
        comments: 'Outstanding repair turnaround! Completely fixed.',
      );

      expect(feedbackSuccess, isTrue);
      expect(complaintProvider.selectedComplaint!.status, 'Closed');
      expect(complaintProvider.selectedComplaint!.feedback, isNotNull);
      expect(complaintProvider.selectedComplaint!.feedback!.rating, 5);
      expect(complaintProvider.selectedComplaint!.closedAt, isNotNull);
    });
  });
}
