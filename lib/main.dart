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
        // 2. Provide other providers depending on DatabaseService
        ChangeNotifierProxyProvider<DatabaseService, InvoiceProvider>(
          create: (context) => InvoiceProvider(context.read<DatabaseService>()),
          update: (_, db, previous) => previous!..updateDbService(db),
        ),
        ChangeNotifierProxyProvider<DatabaseService, DashboardProvider>(
          create: (context) =>
              DashboardProvider(context.read<DatabaseService>()),
          update: (_, db, previous) => previous!..updateDbService(db),
        ),
        ChangeNotifierProxyProvider<DatabaseService, CustomerProvider>(
          create: (context) =>
              CustomerProvider(context.read<DatabaseService>()),
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
