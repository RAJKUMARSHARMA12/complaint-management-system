import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/core/network/api_client.dart';

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
  group('SecureStorageService (InMemoryStorageService)', () {
    late StorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
    });

    test('should save and retrieve auth token', () async {
      await storage.saveToken('jwt-sample-token-123');
      final token = await storage.getToken();
      expect(token, 'jwt-sample-token-123');
    });

    test('should delete auth token', () async {
      await storage.saveToken('jwt-sample-token-123');
      await storage.deleteToken();
      final token = await storage.getToken();
      expect(token, isNull);
    });

    test('should save, retrieve and clear user data', () async {
      final userData = {
        'id': 'u1',
        'name': 'Aarav Mehta',
        'email': 'aarav.mehta@college.edu',
        'role': 'Student',
      };

      await storage.saveUserData(userData);
      final retrieved = await storage.getUserData();

      expect(retrieved, isNotNull);
      expect(retrieved!['name'], 'Aarav Mehta');
      expect(retrieved['role'], 'Student');

      await storage.clearAuth();
      expect(await storage.getToken(), isNull);
      expect(await storage.getUserData(), isNull);
    });
  });

  group('ApiClient Interceptor & Auth Header', () {
    late StorageService storage;
    late ApiClient apiClient;

    setUp(() {
      storage = InMemoryStorageService();
      apiClient = ApiClient(
        storageService: storage,
        baseUrl: 'http://localhost:5001/api',
      );
    });

    test('should attach Authorization Bearer header when token exists', () async {
      await storage.saveToken('my-test-jwt-token');

      RequestOptions? interceptedOptions;
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        interceptedOptions = options;
        return jsonResponse({'success': true});
      });

      final response = await apiClient.get('/complaints');

      expect(response.statusCode, 200);
      expect(interceptedOptions, isNotNull);
      expect(interceptedOptions!.headers['Authorization'], 'Bearer my-test-jwt-token');
      expect(interceptedOptions!.headers['Content-Type'], 'application/json');
    });

    test('should not attach Authorization header when token is absent', () async {
      RequestOptions? interceptedOptions;
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        interceptedOptions = options;
        return jsonResponse({'success': true});
      });

      await apiClient.post('/auth/login', data: {'email': 'a@b.com'});

      expect(interceptedOptions, isNotNull);
      expect(interceptedOptions!.headers['Authorization'], isNull);
    });

    test('should invoke onUnauthorized callback and clear auth on 401', () async {
      await storage.saveToken('expired-token');
      bool unauthorizedCalled = false;

      apiClient = ApiClient(
        storageService: storage,
        baseUrl: 'http://localhost:5001/api',
        onUnauthorized: () {
          unauthorizedCalled = true;
        },
      );

      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        return jsonResponse({'message': 'Invalid token'}, statusCode: 401);
      });

      try {
        await apiClient.get('/complaints');
      } catch (e) {
        expect(e, isA<DioException>());
      }

      expect(unauthorizedCalled, isTrue);
      expect(await storage.getToken(), isNull);
    });
  });
}
