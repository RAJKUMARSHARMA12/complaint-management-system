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
  group('ComplaintProvider Complaint Fetching & Filtering Tests', () {
    test('fetchMyComplaints populates complaints and computes category filters', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      final client = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/complaints/my') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'complaints': [
                        {
                          'id': '1',
                          'complaintId': 'CMP-0001',
                          'title': 'Broken Tap',
                          'description': 'Water leaking in 204',
                          'category': {'name': 'Hostel Maintenance'},
                          'location': 'Hostel B',
                          'priority': 'High',
                          'status': 'Assigned',
                          'images': [],
                          'createdAt': DateTime(2026, 11, 1).toIso8601String(),
                        },
                        {
                          'id': '2',
                          'complaintId': 'CMP-0002',
                          'title': 'Mess Food Quality',
                          'description': 'Food was cold and unhygienic',
                          'category': {'name': 'Mess & Food Services'},
                          'location': 'Central Mess',
                          'priority': 'Medium',
                          'status': 'Resolved',
                          'images': ['https://example.com/food.jpg'],
                          'createdAt': DateTime(2026, 11, 2).toIso8601String(),
                        },
                        {
                          'id': '3',
                          'complaintId': 'CMP-0003',
                          'title': 'WiFi Deadzone',
                          'description': 'No signal on 3rd floor',
                          'category': {'name': 'Computer & Lab Equipment'},
                          'location': 'Library 3rd Floor',
                          'priority': 'Low',
                          'status': 'Closed',
                          'images': [],
                          'createdAt': DateTime(2026, 11, 2).toIso8601String(),
                        },
                      ],
                      'pagination': {'total': 3, 'page': 1, 'pages': 1, 'limit': 10}
                    }
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final provider = ComplaintProvider(
        apiClient: client,
        categoryService: FakeCategoryService(),
      );

      expect(provider.myComplaints.isEmpty, isTrue);
      expect(provider.isLoadingComplaints, isFalse);

      await provider.fetchMyComplaints();

      expect(provider.isLoadingComplaints, isFalse);
      expect(provider.myComplaints.length, equals(3));
      expect(provider.totalComplaintsCount, equals(3));

      // Active = 'Submitted', 'Assigned', 'In Progress'
      expect(provider.activeComplaints.length, equals(1));
      expect(provider.activeComplaints.first.complaintId, equals('CMP-0001'));
      expect(provider.activeComplaintsCount, equals(1));

      // Resolved
      expect(provider.resolvedComplaints.length, equals(1));
      expect(provider.resolvedComplaints.first.complaintId, equals('CMP-0002'));
      expect(provider.resolvedComplaintsCount, equals(1));

      // Closed
      expect(provider.closedComplaints.length, equals(1));
      expect(provider.closedComplaints.first.complaintId, equals('CMP-0003'));
      expect(provider.closedComplaintsCount, equals(1));
    });

    test('fetchMyComplaints handles error and sets complaintsError', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      final client = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 500,
                  data: {'message': 'Server error fetching grievances'},
                ),
              ),
            );
          },
        ),
      );

      final provider = ComplaintProvider(
        apiClient: client,
        categoryService: FakeCategoryService(),
      );

      await provider.fetchMyComplaints();

      expect(provider.isLoadingComplaints, isFalse);
      expect(provider.myComplaints.isEmpty, isTrue);
      expect(provider.complaintsError, contains('Server error'));
    });
  });
}
