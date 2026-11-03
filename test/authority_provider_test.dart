import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/models/category_model.dart';
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
      : super(apiClient: ApiClient(storageService: FakeStorageService()));

  @override
  Future<List<CategoryModel>> getCategories() async => [];
}

void main() {
  group('ComplaintProvider Authority Queue & Status Update (TDD)', () {
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

    test('fetchAssignedComplaints populates assigned complaints and KPI metrics', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/complaints/assigned') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [
                        {
                          '_id': 'cmp1',
                          'complaintId': 'CMP-0001',
                          'title': 'Leaking Tap in B-Block',
                          'category': {'name': 'Hostel Maintenance'},
                          'priority': 'High',
                          'status': 'Assigned',
                          'dueDate': '2026-11-05T10:00:00.000Z',
                        },
                        {
                          '_id': 'cmp2',
                          'complaintId': 'CMP-0002',
                          'title': 'Wi-Fi down in Lib',
                          'category': {'name': 'IT Services'},
                          'priority': 'Medium',
                          'status': 'In Progress',
                          'dueDate': '2026-11-06T10:00:00.000Z',
                        },
                        {
                          '_id': 'cmp3',
                          'complaintId': 'CMP-0003',
                          'title': 'Broken desk LH-101',
                          'category': {'name': 'Infrastructure'},
                          'priority': 'Low',
                          'status': 'Resolved',
                          'dueDate': '2026-11-04T10:00:00.000Z',
                        },
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

      expect(provider.assignedComplaints, isEmpty);
      expect(provider.assignedCount, 0);

      await provider.fetchAssignedComplaints();

      expect(provider.isLoadingAssigned, isFalse);
      expect(provider.assignedComplaints.length, 3);
      expect(provider.assignedCount, 1);
      expect(provider.inProgressCount, 1);
      expect(provider.resolvedCount, 1);
    });

    test('updateComplaintStatus dispatches PATCH and updates state in queue', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/complaints/assigned') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [
                        {
                          '_id': 'cmp1',
                          'complaintId': 'CMP-0001',
                          'title': 'Leaking Tap',
                          'category': {'name': 'Hostel Maintenance'},
                          'priority': 'High',
                          'status': 'Assigned',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/complaints/cmp1/status' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Status updated successfully',
                    'data': {
                      'id': 'cmp1',
                      'complaintId': 'CMP-0001',
                      'status': 'In Progress',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await provider.fetchAssignedComplaints();
      expect(provider.assignedComplaints.first.status, 'Assigned');

      final success = await provider.updateComplaintStatus(
        complaintId: 'cmp1',
        nextStatus: 'In Progress',
        remark: 'Work started on plumbing repair',
      );

      expect(success, isTrue);
      expect(provider.isUpdatingStatus, isFalse);
      expect(provider.assignedComplaints.first.status, 'In Progress');
    });

    test('getAllowedTransitions returns correct legal states according to FSM', () {
      expect(provider.getAllowedTransitions('Submitted'), ['Assigned']);
      expect(provider.getAllowedTransitions('Assigned'), ['In Progress']);
      expect(provider.getAllowedTransitions('In Progress'), ['Resolved']);
      expect(provider.getAllowedTransitions('Resolved'), ['Closed', 'In Progress']);
      expect(provider.getAllowedTransitions('Closed'), isEmpty);
    });
  });
}
