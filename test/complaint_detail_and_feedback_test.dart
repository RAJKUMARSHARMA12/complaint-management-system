import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/providers/complaint_provider.dart';
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
      : super(
          apiClient: ApiClient(storageService: FakeStorageService()),
        );

  @override
  Future<List<CategoryModel>> getCategories() async {
    return [
      CategoryModel(id: 'c1', name: 'Hostel Maintenance', department: 'Hostel'),
    ];
  }
}

void main() {
  group('ComplaintProvider Detail, Remarks, and Feedback (TDD)', () {
    late ApiClient apiClient;
    late Dio dio;
    late ComplaintProvider provider;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      apiClient = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );
      provider = ComplaintProvider(
        apiClient: apiClient,
        categoryService: FakeCategoryService(),
      );
    });

    test('fetchComplaintById populates selectedComplaint and clears loading state', () async {
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
                      'title': 'Broken Geyser',
                      'description': 'Water is freezing cold in Room 302',
                      'category': {'name': 'Hostel Maintenance'},
                      'location': 'Hostel A, Room 302',
                      'priority': 'High',
                      'status': 'In Progress',
                      'dueDate': '2026-11-05T12:00:00.000Z',
                      'remarks': [
                        {
                          'id': 'rem1',
                          'role': 'authority',
                          'text': 'Plumber dispatched to inspect heating element',
                          'user': {'name': 'Warden Sharma'},
                          'createdAt': '2026-11-03T10:00:00.000Z',
                        }
                      ],
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      expect(provider.selectedComplaint, isNull);
      await provider.fetchComplaintById('cmp123');

      expect(provider.isLoadingDetail, isFalse);
      expect(provider.detailError, isNull);
      expect(provider.selectedComplaint, isNotNull);
      expect(provider.selectedComplaint!.complaintId, 'CMP-2026-0001');
      expect(provider.selectedComplaint!.title, 'Broken Geyser');
      expect(provider.selectedComplaint!.status, 'In Progress');
      expect(provider.selectedComplaint!.remarks.length, 1);
      expect(provider.selectedComplaint!.remarks.first.text, 'Plumber dispatched to inspect heating element');
      expect(provider.selectedComplaint!.remarks.first.userName, 'Warden Sharma');
    });

    test('fetchComplaintById captures error on failure', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'message': 'Complaint not found with id: cmp999'},
                ),
              ),
            );
          },
        ),
      );

      await provider.fetchComplaintById('cmp999');

      expect(provider.isLoadingDetail, isFalse);
      expect(provider.selectedComplaint, isNull);
      expect(provider.detailError, 'Complaint not found with id: cmp999');
    });

    test('addRemark sends remark text and appends new remark to selectedComplaint', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/complaints/cmp123/remarks') && options.method == 'POST') {
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
                          'id': 'rem1',
                          'role': 'student',
                          'text': 'Thank you for following up!',
                          'createdAt': '2026-11-03T11:00:00.000Z',
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

      provider.setSelectedComplaint(
        ComplaintModel(
          id: 'cmp123',
          complaintId: 'CMP-2026-0001',
          title: 'Broken Geyser',
          description: 'Water is cold',
          categoryName: 'Hostel Maintenance',
          priority: 'High',
          status: 'In Progress',
        ),
      );

      final success = await provider.addRemark(
        complaintId: 'cmp123',
        text: 'Thank you for following up!',
        userName: 'Aarav Mehta',
        userRole: 'student',
      );

      expect(success, isTrue);
      expect(provider.isPostingRemark, isFalse);
      expect(provider.selectedComplaint, isNotNull);
      expect(provider.selectedComplaint!.remarks.length, 1);
      expect(provider.selectedComplaint!.remarks.last.text, 'Thank you for following up!');
    });

    test('submitFeedback posts rating & comments and transitions ticket to Closed', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/complaints/cmp123/feedback') && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Feedback recorded and complaint closed',
                    'data': {
                      'complaintId': 'CMP-2026-0001',
                      'status': 'Closed',
                      'feedback': {
                        'rating': 5,
                        'comment': 'Issue resolved completely, fast response!',
                        'submittedAt': '2026-11-03T12:00:00.000Z',
                      },
                      'closedAt': '2026-11-03T12:00:00.000Z',
                    }
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      provider.setSelectedComplaint(
        ComplaintModel(
          id: 'cmp123',
          complaintId: 'CMP-2026-0001',
          title: 'Broken Geyser',
          description: 'Water is cold',
          categoryName: 'Hostel Maintenance',
          priority: 'High',
          status: 'Resolved',
        ),
      );

      final success = await provider.submitFeedback(
        complaintId: 'cmp123',
        rating: 5,
        comments: 'Issue resolved completely, fast response!',
      );

      expect(success, isTrue);
      expect(provider.isSubmittingFeedback, isFalse);
      expect(provider.selectedComplaint, isNotNull);
      expect(provider.selectedComplaint!.status, 'Closed');
      expect(provider.selectedComplaint!.feedback, isNotNull);
      expect(provider.selectedComplaint!.feedback!.rating, 5);
      expect(provider.selectedComplaint!.feedback!.comments, 'Issue resolved completely, fast response!');
    });
  });
}
