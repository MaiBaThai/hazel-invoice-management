import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/core/providers/dashboard_provider.dart';
import 'package:nms/core/providers/customer_provider.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/core/providers/expense_provider.dart';
import 'package:nms/core/providers/auth_provider.dart';
import 'package:nms/features/invoice/invoice_page.dart';
import 'package:nms/features/expenses/expenses_page.dart';
import 'package:nms/features/dashboard/dashboard_page.dart';
import 'package:nms/features/customers/customers_page.dart';
import 'package:nms/features/settings/settings_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;
import 'package:nms/data/services/database_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GlobalKey<MainNavigationPageState> mainNavKey =
    GlobalKey<MainNavigationPageState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const String environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: environment == 'prod'
            ? prod.DefaultFirebaseOptions.currentPlatform
            : dev.DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('==================================================');
    debugPrint('FATAL: Firebase initialization failed: $e');
    debugPrint('Please ensure the running flavor matches the --dart-define=ENVIRONMENT option.');
    debugPrint('For example, use: flutter run --flavor prod --dart-define=ENVIRONMENT=prod');
    debugPrint('==================================================');
    rethrow;
  }

  // Initialize Google Sign In for v7.2.0 compatibility
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    debugPrint('Google Sign-In initialization warning: $e');
    // On web, if this fails, we might need to provide a clientId explicitly.
  }

  final authProvider = AuthProvider();
  // Don't await here to avoid blocking app startup if Auth is slow (e.g. in Incognito)
  authProvider.signInSilently();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ProxyProvider<AuthProvider, DatabaseService>(
          update: (_, auth, __) => DatabaseService(
            userId: auth.user?.uid,
            isAnonymous: auth.isAnonymous,
          ),
        ),
        ChangeNotifierProxyProvider<DatabaseService, CustomerProvider>(
          create: (context) =>
              CustomerProvider(context.read<DatabaseService>()),
          update: (_, db, previous) => previous!..updateDbService(db),
        ),
        ChangeNotifierProxyProvider2<DatabaseService, CustomerProvider, InvoiceProvider>(
          create: (context) => InvoiceProvider(context.read<DatabaseService>()),
          update: (_, db, customerProvider, previous) => previous!
            ..updateDbService(db)
            ..updateCustomerProvider(customerProvider),
        ),
        ChangeNotifierProxyProvider<DatabaseService, DashboardProvider>(
          create: (context) =>
              DashboardProvider(context.read<DatabaseService>()),
          update: (_, db, previous) => previous!..updateDbService(db),
        ),
        ChangeNotifierProxyProvider<DatabaseService, SettingsProvider>(
          create: (context) =>
              SettingsProvider(context.read<DatabaseService>())..loadSettings(),
          update: (_, db, previous) => previous!..updateDbService(db),
        ),
        ChangeNotifierProxyProvider<DatabaseService, ExpenseProvider>(
          create: (context) => ExpenseProvider(context.read<DatabaseService>()),
          update: (_, db, previous) => previous!..updateDbService(db),
        ),
      ],
      child: const NMSApp(),
    ),
  );
}

class NMSApp extends StatelessWidget {
  const NMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NMS v1.4.1',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
      ),
      home: MainNavigationPage(key: mainNavKey),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    InvoicePage(),
    ExpensesPage(),
    DashboardPage(),
    CustomersPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      Provider.of<DashboardProvider>(context, listen: false)
          .loadDashboardData();
    } else if (index == 3) {
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    }
  }

  void switchTab(int index) {
    _onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final customer = Provider.of<CustomerProvider>(context);

    final showLoading = auth.isInitializing || 
        auth.user == null ||
        settings.isLoading || 
        settings.settings == null || 
        !customer.hasLoadedOnce;

    if (showLoading) {
      return const AppLoadingScreen();
    }

    return Scaffold(
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Invoice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade400,
              Colors.pink.shade600,
              Colors.purple.shade800,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container with Glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              const Text(
                'My Salon',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Managing Your Success',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 48),
              // Premium Linear Progress Bar
              SizedBox(
                width: 220,
                height: 6,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Loading Text
              Text(
                'Initializing salon data...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
