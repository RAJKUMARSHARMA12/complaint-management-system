import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/providers/auth_provider.dart';

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
  group('AuthProvider State & Flows', () {
    late StorageService storage;
    late ApiClient apiClient;
    late AuthProvider authProvider;

    setUp(() {
      storage = InMemoryStorageService();
      apiClient = ApiClient(
        storageService: storage,
        baseUrl: 'http://localhost:5001/api',
      );
      authProvider = AuthProvider(
        apiClient: apiClient,
        storageService: storage,
      );
    });

    test('initial state should be unauthenticated and not loading', () {
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.token, isNull);
      expect(authProvider.errorMessage, isNull);
    });

    test('login success updates state and persists credentials', () async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        expect(options.path, '/auth/login');
        return jsonResponse({
          'message': 'Login successful',
          'token': 'mock-jwt-token-xyz',
          'user': {
            'id': 'u1',
            'name': 'Aarav Mehta',
            'email': 'aarav.mehta@college.edu',
            'role': 'Student',
            'department': 'Computer Science',
          },
        });
      });

      final success = await authProvider.login(
        'aarav.mehta@college.edu',
        'StudentPassword@123',
      );

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.name, 'Aarav Mehta');
      expect(authProvider.token, 'mock-jwt-token-xyz');
      expect(await storage.getToken(), 'mock-jwt-token-xyz');
      final savedUser = await storage.getUserData();
      expect(savedUser?['name'], 'Aarav Mehta');
    });

    test('login failure sets error message and leaves unauthenticated', () async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        return jsonResponse(
          {'message': 'Invalid email or password'},
          statusCode: 401,
        );
      });

      final success = await authProvider.login(
        'wrong@college.edu',
        'BadPassword',
      );

      expect(success, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.errorMessage, 'Invalid email or password');
      expect(await storage.getToken(), isNull);
    });

    test('register success stores token and user', () async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        expect(options.path, '/auth/register');
        return jsonResponse(
          {
            'message': 'Registration successful',
            'token': 'new-user-jwt',
            'user': {
              'id': 'u2',
              'name': 'New Student',
              'email': 'new.student@college.edu',
              'role': 'Student',
              'department': 'Mechanical',
            },
          },
          statusCode: 201,
        );
      });

      final success = await authProvider.register(
        name: 'New Student',
        email: 'new.student@college.edu',
        password: 'Password@123',
        role: 'Student',
        department: 'Mechanical',
      );

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.name, 'New Student');
      expect(authProvider.token, 'new-user-jwt');
    });

    test('tryAutoLogin restores session from storage', () async {
      await storage.saveToken('persisted-token');
      await storage.saveUserData({
        'id': 'u1',
        'name': 'Aarav Mehta',
        'email': 'aarav.mehta@college.edu',
        'role': 'Student',
      });

      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        expect(options.path, '/auth/me');
        return jsonResponse({
          'user': {
            'id': 'u1',
            'name': 'Aarav Mehta',
            'email': 'aarav.mehta@college.edu',
            'role': 'Student',
          },
        });
      });

      final loggedIn = await authProvider.tryAutoLogin();

      expect(loggedIn, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.email, 'aarav.mehta@college.edu');
      expect(authProvider.token, 'persisted-token');
    });

    test('logout clears session from memory and storage', () async {
      await storage.saveToken('active-token');
      await storage.saveUserData({'id': 'u1', 'name': 'Aarav'});

      await authProvider.tryAutoLogin();
      await authProvider.logout();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);
      expect(authProvider.token, isNull);
      expect(await storage.getToken(), isNull);
      expect(await storage.getUserData(), isNull);
    });
  });
}
