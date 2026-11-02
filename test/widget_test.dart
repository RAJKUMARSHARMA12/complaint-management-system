import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/main.dart';

void main() {
  testWidgets('App launches and renders SplashScreen', (WidgetTester tester) async {
    final storage = InMemoryStorageService();
    final apiClient = ApiClient(
      storageService: storage,
      baseUrl: 'http://localhost:5001/api',
    );

    await tester.pumpWidget(
      MyApp(
        storageService: storage,
        apiClient: apiClient,
      ),
    );

    expect(find.text('CampusVoice'), findsOneWidget);
    expect(find.text('Campus Grievance & Redressal System'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
