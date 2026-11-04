import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';

class FakeStorageService implements StorageService {
  String? token = 'jwt_cloud_test_token_2026';

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

void main() {
  group('Day 19 - Cloud Deployment & Mobile Client Configuration Tests', () {
    late FakeStorageService storage;

    setUp(() {
      storage = FakeStorageService();
    });

    test('ApiClient defaults to the live Render cloud domain', () {
      expect(ApiClient.liveCloudUrl, 'https://complaint-management-system-fesn.onrender.com/api');
      expect(ApiClient.defaultBaseUrl, 'https://complaint-management-system-fesn.onrender.com/api');

      final client = ApiClient(storageService: storage);
      expect(client.dio.options.baseUrl, 'https://complaint-management-system-fesn.onrender.com/api');
    });

    test('ApiClient allows custom baseUrl override', () {
      final client = ApiClient(
        storageService: storage,
        baseUrl: 'http://localhost:5001/api',
      );
      expect(client.dio.options.baseUrl, 'http://localhost:5001/api');
    });

    test('ApiClient configures mobile cellular timeouts (15s connect / receive)', () {
      final client = ApiClient(storageService: storage);
      expect(client.dio.options.connectTimeout, const Duration(seconds: 15));
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 15));
    });

    test('ApiClient automatically injects Bearer token header on outbound requests', () async {
      final dio = Dio();
      RequestOptions? capturedOptions;

      dio.httpClientAdapter = MockAdapter((options) async {
        capturedOptions = options;
        return ResponseBody.fromString(
          jsonEncode({'status': 'ok', 'service': 'CampusVoice API'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        storageService: storage,
        customDio: dio,
      );

      final response = await client.get('/health');
      expect(response.statusCode, 200);
      expect(response.data['service'], 'CampusVoice API');
      expect(capturedOptions?.headers['Authorization'], 'Bearer jwt_cloud_test_token_2026');
    });

    test('AuthInterceptor triggers onUnauthorized callback when receiving 401', () async {
      bool unauthorizedTriggered = false;
      final dio = Dio();

      dio.httpClientAdapter = MockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Token expired'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final client = ApiClient(
        storageService: storage,
        customDio: dio,
        onUnauthorized: () {
          unauthorizedTriggered = true;
        },
      );

      try {
        await client.get('/protected-route');
      } catch (_) {}

      expect(unauthorizedTriggered, isTrue);
    });
  });
}
