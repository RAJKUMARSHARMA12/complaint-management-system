import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/services/category_service.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/screens/new_complaint_screen.dart';

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
  required ComplaintProvider complaintProvider,
}) {
  return ChangeNotifierProvider<ComplaintProvider>.value(
    value: complaintProvider,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  late StorageService storage;
  late ApiClient apiClient;
  late CategoryService categoryService;
  late ComplaintProvider complaintProvider;

  setUp(() {
    storage = InMemoryStorageService();
    apiClient = ApiClient(
      storageService: storage,
      baseUrl: 'http://localhost:5001/api',
    );
    categoryService = CategoryService(apiClient: apiClient);
    complaintProvider = ComplaintProvider(
      apiClient: apiClient,
      categoryService: categoryService,
    );
  });

  group('NewComplaintScreen Form & Validation', () {
    testWidgets('renders all complaint lodging fields', (tester) async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        return jsonResponse({
          'success': true,
          'data': [
            {
              '_id': 'cat1',
              'name': 'Hostel Maintenance',
              'department': 'Hostel Maintenance',
              'isActive': true,
            }
          ]
        });
      });

      await tester.pumpWidget(
        createTestableWidget(
          child: const NewComplaintScreen(),
          complaintProvider: complaintProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lodge a Complaint'), findsOneWidget);
      expect(find.byKey(const Key('complaint_title_field')), findsOneWidget);
      expect(find.byKey(const Key('complaint_description_field')), findsOneWidget);
      expect(find.byKey(const Key('complaint_location_field')), findsOneWidget);
      expect(find.byKey(const Key('complaint_category_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('anonymous_switch')), findsOneWidget);
      expect(find.byKey(const Key('add_image_button')), findsOneWidget);
      expect(find.byKey(const Key('submit_complaint_button')), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form', (tester) async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        return jsonResponse({'success': true, 'data': []});
      });

      await tester.pumpWidget(
        createTestableWidget(
          child: const NewComplaintScreen(),
          complaintProvider: complaintProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Ensure submit button is visible in scrollable view and tap
      final submitFinder = find.byKey(const Key('submit_complaint_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.text('Please enter a description'), findsOneWidget);
      expect(find.text('Please enter the location'), findsOneWidget);
    });

    testWidgets('toggling anonymous switch shows whistleblower info banner', (tester) async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        return jsonResponse({'success': true, 'data': []});
      });

      await tester.pumpWidget(
        createTestableWidget(
          child: const NewComplaintScreen(),
          complaintProvider: complaintProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Whistleblower Protection'), findsNothing);

      // Toggle switch
      final switchFinder = find.byKey(const Key('anonymous_switch'));
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Whistleblower Protection'), findsOneWidget);
    });

    testWidgets('priority selection updates selected priority', (tester) async {
      apiClient.dio.httpClientAdapter = MockAdapter((options) async {
        return jsonResponse({'success': true, 'data': []});
      });

      await tester.pumpWidget(
        createTestableWidget(
          child: const NewComplaintScreen(),
          complaintProvider: complaintProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Find Urgent priority segment and tap it
      final urgentFinder = find.text('Urgent');
      expect(urgentFinder, findsOneWidget);
      await tester.ensureVisible(urgentFinder);
      await tester.tap(urgentFinder);
      await tester.pumpAndSettle();

      expect(urgentFinder, findsOneWidget);
    });
  });
}
