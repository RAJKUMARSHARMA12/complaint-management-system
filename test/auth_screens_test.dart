import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/screens/splash_screen.dart';
import 'package:major_project/screens/login_screen.dart';
import 'package:major_project/screens/register_screen.dart';

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

Widget createTestableWidget({
  required Widget child,
  required AuthProvider authProvider,
}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(
      home: child,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const Scaffold(body: Text('Home Screen')),
      },
    ),
  );
}

void main() {
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

  group('SplashScreen', () {
    testWidgets('renders CampusVoice title and loading indicator', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const SplashScreen(),
          authProvider: authProvider,
        ),
      );

      expect(find.text('CampusVoice'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoginScreen Form & Validation', () {
    testWidgets('renders all login fields and links', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const LoginScreen(),
          authProvider: authProvider,
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.text("Don't have an account? Sign Up"), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const LoginScreen(),
          authProvider: authProvider,
        ),
      );

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const LoginScreen(),
          authProvider: authProvider,
        ),
      );

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });
  });

  group('RegisterScreen Form & Validation', () {
    testWidgets('renders all registration fields', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const RegisterScreen(),
          authProvider: authProvider,
        ),
      );

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byKey(const Key('register_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_role_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('register_button')), findsOneWidget);
    });

    testWidgets('validates required fields on register submit', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const RegisterScreen(),
          authProvider: authProvider,
        ),
      );

      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });
  });
}
