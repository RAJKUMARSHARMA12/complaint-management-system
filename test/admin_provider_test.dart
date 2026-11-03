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
  group('ComplaintProvider Admin Master Console & Delegation (TDD)', () {
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

    test('fetchAllComplaintsAdmin fetches master ticket list and applies filters', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/complaints') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [
                        {
                          '_id': 'c1',
                          'complaintId': 'CMP-0001',
                          'title': 'Leaking Tap',
                          'category': {'name': 'Hostel Maintenance'},
                          'status': 'Submitted',
                          'priority': 'Medium',
                          'isEscalated': false,
                        },
                        {
                          '_id': 'c2',
                          'complaintId': 'CMP-0002',
                          'title': 'Wi-Fi Router Dead',
                          'category': {'name': 'IT Services'},
                          'status': 'In Progress',
                          'priority': 'Urgent',
                          'isEscalated': true,
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

      expect(provider.adminComplaints, isEmpty);

      await provider.fetchAllComplaintsAdmin();

      expect(provider.isLoadingAdminComplaints, isFalse);
      expect(provider.adminComplaints.length, 2);
      expect(provider.adminComplaints[0].complaintId, 'CMP-0001');
      expect(provider.adminComplaints[1].isEscalated, isTrue);
    });

    test('fetchAuthorityStaff fetches authority user accounts for assignment dropdown', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
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
                          'id': 'auth1',
                          'name': 'Warden Sharma',
                          'email': 'warden@college.edu',
                          'role': 'authority',
                          'department': 'Hostel Maintenance',
                          'isActive': true,
                        },
                        {
                          'id': 'auth2',
                          'name': 'Mr. Spark',
                          'email': 'electrician@college.edu',
                          'role': 'authority',
                          'department': 'Electrical Maintenance',
                          'isActive': true,
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

      expect(provider.authorityStaff, isEmpty);

      await provider.fetchAuthorityStaff();

      expect(provider.isLoadingStaff, isFalse);
      expect(provider.authorityStaff.length, 2);
      expect(provider.authorityStaff.first.name, 'Warden Sharma');
      expect(provider.authorityStaff.first.department, 'Hostel Maintenance');
    });

    test('assignComplaint delegates ticket to authority and updates ticket status to Assigned', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/complaints') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [
                        {
                          '_id': 'c1',
                          'complaintId': 'CMP-0001',
                          'title': 'Leaking Tap',
                          'category': {'name': 'Hostel Maintenance'},
                          'status': 'Submitted',
                          'priority': 'Medium',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/complaints/c1/assign' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Complaint assigned successfully',
                    'data': {
                      'id': 'c1',
                      'complaintId': 'CMP-0001',
                      'status': 'Assigned',
                      'assignedTo': 'auth1',
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await provider.fetchAllComplaintsAdmin();
      expect(provider.adminComplaints.first.status, 'Submitted');

      final success = await provider.assignComplaint(
        complaintId: 'c1',
        authorityId: 'auth1',
        authorityName: 'Warden Sharma',
        remark: 'Assigned for plumbing resolution',
      );

      expect(success, isTrue);
      expect(provider.isAssigning, isFalse);
      expect(provider.adminComplaints.first.status, 'Assigned');
      expect(provider.adminComplaints.first.assignedToName, 'Warden Sharma');
    });
  });
}
