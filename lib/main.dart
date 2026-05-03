import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/core/providers/dashboard_provider.dart';
import 'package:nms/core/providers/customer_provider.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/core/providers/expense_provider.dart';
import 'package:nms/features/invoice/invoice_page.dart';
import 'package:nms/features/expenses/expenses_page.dart';
import 'package:nms/features/dashboard/dashboard_page.dart';
import 'package:nms/features/customers/customers_page.dart';
import 'package:nms/features/settings/settings_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
  
  await Firebase.initializeApp(
    options: environment == 'prod' 
        ? prod.DefaultFirebaseOptions.currentPlatform 
        : dev.DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
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
      title: 'NMS v1.3.9',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
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
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
    } else if (index == 3) {
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    }
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
