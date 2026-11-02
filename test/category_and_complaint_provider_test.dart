import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/services/category_service.dart';
import 'package:major_project/providers/complaint_provider.dart';

class MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(dynamic data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late StorageService storage;
  late ApiClient apiClient;

  setUp(() {
    storage = InMemoryStorageService();
    apiClient = ApiClient(
      storageService: storage,
      baseUrl: 'http://localhost:5001/api',
    );
  });

  group('CategoryService', () {
    test('getCategories parses category list successfully', () async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        expect(options.path, '/categories');
        return jsonResponse({
          'success': true,
          'count': 2,
          'data': [
            {
              '_id': 'cat1',
              'name': 'Hostel Maintenance',
              'description': 'Hostel infrastructure',
              'department': 'Hostel Maintenance',
              'isActive': true,
            },
            {
              '_id': 'cat2',
              'name': 'Electrical & Power',
              'description': 'Electrical issues',
              'department': 'Electrical Maintenance',
              'isActive': true,
            }
          ]
        });
      });

      final service = CategoryService(apiClient: apiClient);
      final categories = await service.getCategories();

      expect(categories.length, 2);
      expect(categories[0].id, 'cat1');
      expect(categories[0].name, 'Hostel Maintenance');
      expect(categories[1].name, 'Electrical & Power');
    });
  });

  group('ComplaintProvider', () {
    late CategoryService categoryService;
    late ComplaintProvider provider;

    setUp(() {
      categoryService = CategoryService(apiClient: apiClient);
      provider = ComplaintProvider(
        apiClient: apiClient,
        categoryService: categoryService,
      );
    });

    test('initial state is clean', () {
      expect(provider.categories, isEmpty);
      expect(provider.isLoadingCategories, isFalse);
      expect(provider.isSubmitting, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('fetchCategories loads categories into state', () async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        return jsonResponse({
          'success': true,
          'data': [
            {
              '_id': 'c1',
              'name': 'Hostel Maintenance',
              'department': 'Hostel Maintenance',
              'isActive': true,
            }
          ]
        });
      });

      await provider.fetchCategories();

      expect(provider.categories.length, 1);
      expect(provider.categories.first.name, 'Hostel Maintenance');
      expect(provider.isLoadingCategories, isFalse);
    });

    test('submitComplaint sends multipart data and creates complaint', () async {
      RequestOptions? interceptedOptions;

      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        interceptedOptions = options;
        expect(options.path, '/complaints');
        expect(options.method, 'POST');
        return jsonResponse({
          'success': true,
          'message': 'Complaint lodged successfully',
          'data': {
            '_id': 'cmp1001',
            'complaintId': 'CMP-2026-0001',
            'title': 'Broken Geyser in Hostel 3',
            'description': 'Geyser is not heating water properly',
            'category': {
              '_id': 'c1',
              'name': 'Hostel Maintenance',
              'department': 'Hostel Maintenance',
            },
            'location': 'Hostel 3, Room 204',
            'priority': 'High',
            'isAnonymous': false,
            'images': ['http://localhost:8080/uploads/test.jpg'],
            'status': 'Submitted',
            'createdAt': '2026-11-02T10:00:00.000Z',
          }
        }, statusCode: 201);
      });

      final success = await provider.submitComplaint(
        title: 'Broken Geyser in Hostel 3',
        description: 'Geyser is not heating water properly',
        categoryId: 'c1',
        location: 'Hostel 3, Room 204',
        priority: 'High',
        isAnonymous: false,
        imagePaths: [],
      );

      expect(success, isTrue);
      expect(provider.isSubmitting, isFalse);
      expect(provider.lastCreatedComplaint, isNotNull);
      expect(provider.lastCreatedComplaint!.complaintId, 'CMP-2026-0001');
      expect(interceptedOptions, isNotNull);
      expect(interceptedOptions!.data, isA<FormData>());
      final formData = interceptedOptions!.data as FormData;
      expect(formData.fields.any((f) => f.key == 'title' && f.value == 'Broken Geyser in Hostel 3'), isTrue);
      expect(formData.fields.any((f) => f.key == 'isAnonymous' && f.value == 'false'), isTrue);
    });

    test('submitComplaint sets error message on failure', () async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        return jsonResponse({
          'success': false,
          'message': 'Category does not exist',
        }, statusCode: 400);
      });

      final success = await provider.submitComplaint(
        title: 'Broken Geyser',
        description: 'No hot water in bathroom',
        categoryId: 'invalid-cat',
        location: 'Hostel 3',
        priority: 'Medium',
        isAnonymous: true,
      );

      expect(success, isFalse);
      expect(provider.isSubmitting, isFalse);
      expect(provider.errorMessage, 'Category does not exist');
      expect(provider.lastCreatedComplaint, isNull);
    });
  });
}
