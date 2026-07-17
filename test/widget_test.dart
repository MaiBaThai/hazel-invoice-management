import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:nms/core/providers/auth_provider.dart';
import 'package:nms/core/providers/booking_provider.dart';
import 'package:nms/core/providers/customer_provider.dart';
import 'package:nms/core/providers/dashboard_provider.dart';
import 'package:nms/core/providers/expense_provider.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/core/providers/subscription_provider.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/data/services/migration_service.dart';
import 'package:nms/main.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUser extends Mock implements User {}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    registerFallbackValue(const Duration(seconds: 5));
  });

  testWidgets('App renders pages and navigation bar without crashing', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth();
    final mockGoogleSignIn = MockGoogleSignIn();
    final mockUser = MockUser();

    when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
    when(() => mockAuth.userChanges()).thenAnswer((_) => Stream.value(mockUser));
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test_user_123');
    when(() => mockUser.isAnonymous).thenReturn(false);

    final fakeDb = FakeFirebaseFirestore();
    final migrationService = MigrationService(firestore: fakeDb);
    
    final dbService = DatabaseService(
      userId: 'test_user_123',
      isAnonymous: false,
      firestore: fakeDb,
    );

    final authProvider = AuthProvider(
      auth: mockAuth,
      googleSignIn: mockGoogleSignIn,
      migrationService: migrationService,
    );

    final subscriptionProvider = SubscriptionProvider(dbService, auth: mockAuth);
    final customerProvider = CustomerProvider(dbService)..loadCustomers();
    final invoiceProvider = InvoiceProvider(dbService);
    final dashboardProvider = DashboardProvider(dbService);
    final settingsProvider = SettingsProvider(dbService)..loadSettings();
    final expenseProvider = ExpenseProvider(dbService);
    final bookingProvider = BookingProvider(dbService, googleSignIn: mockGoogleSignIn);

    invoiceProvider.updateCustomerProvider(customerProvider);
    invoiceProvider.updateSubscriptionProvider(subscriptionProvider);
    customerProvider.updateSubscriptionProvider(subscriptionProvider);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          Provider<DatabaseService>.value(value: dbService),
          ChangeNotifierProvider<SubscriptionProvider>.value(value: subscriptionProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
          ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
          ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
          ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
        ],
        child: const MaterialApp(
          home: MainNavigationPage(),
        ),
      ),
    );

    // Let any async loading finish and settle
    await tester.pump();
    await tester.pumpAndSettle();
  });
}
