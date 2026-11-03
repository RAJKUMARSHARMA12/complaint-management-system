import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/services/category_service.dart';
import 'package:major_project/providers/auth_provider.dart';
import 'package:major_project/providers/complaint_provider.dart';
import 'package:major_project/providers/notification_provider.dart';
import 'package:major_project/screens/login_screen.dart';
import 'package:major_project/screens/register_screen.dart';
import 'package:major_project/screens/splash_screen.dart';
import 'package:major_project/screens/new_complaint_screen.dart';
import 'package:major_project/screens/student_home_screen.dart';
import 'package:major_project/screens/my_complaints_screen.dart';
import 'package:major_project/screens/notification_inbox_screen.dart';
import 'package:major_project/screens/complaint_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final StorageService? storageService;
  final ApiClient? apiClient;

  const MyApp({
    super.key,
    this.storageService,
    this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStorage = storageService ?? SecureStorageService();
    final effectiveApiClient = apiClient ??
        ApiClient(
          storageService: effectiveStorage,
        );

    final effectiveCategoryService = CategoryService(apiClient: effectiveApiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            apiClient: effectiveApiClient,
            storageService: effectiveStorage,
          ),
        ),
        ChangeNotifierProvider<ComplaintProvider>(
          create: (_) => ComplaintProvider(
            apiClient: effectiveApiClient,
            categoryService: effectiveCategoryService,
          ),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(
            apiClient: effectiveApiClient,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'CampusVoice',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const StudentHomeScreen(),
          '/my-complaints': (context) => const MyComplaintsScreen(),
          '/new-complaint': (context) => const NewComplaintScreen(),
          '/notifications': (context) => const NotificationInboxScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/complaint-detail') {
            final complaintId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(complaintId: complaintId),
            );
          }
          return null;
        },
      ),
    );
  }
}

class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusVoice Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${user?.name ?? "User"}!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${user?.role ?? "Student"} • ${user?.department ?? "General"}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Campus Grievance & Redressal System\nTap below to lodge a new complaint',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new_complaint_fab'),
        onPressed: () {
          Navigator.pushNamed(context, '/new-complaint');
        },
        icon: const Icon(Icons.add),
        label: const Text('Raise Complaint'),
      ),
    );
  }
}
