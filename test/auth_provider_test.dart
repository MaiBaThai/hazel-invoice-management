import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:nms/data/services/migration_service.dart';
import 'package:nms/core/providers/auth_provider.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUser extends Mock implements User {}
class MockAuthCredential extends Mock implements AuthCredential {}

void main() {
  group('AuthProvider Apple Sign-In Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockUser mockUser;
    late MigrationService fakeMigrationService;
    late AuthProvider authProvider;
    
    // Register fallback values for mocktail
    setUpAll(() {
      registerFallbackValue(MockAuthCredential());
    });

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockUser = MockUser();
      fakeMigrationService = MigrationService(firestore: FakeFirebaseFirestore());

      // Mock auth state stream to emit current mocked user dynamically
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockAuth.currentUser));
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockUser.reload()).thenAnswer((_) async {});

      // Setup the MethodChannel mock for sign_in_with_apple
      TestWidgetsFlutterBinding.ensureInitialized();
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.aboutyou.dart_packages.sign_in_with_apple'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isAvailable') {
            return true;
          }
          if (methodCall.method == 'performAuthorizationRequest') {
            return {
              'type': 'appleid', // Required type value for parsing Apple ID credential
              'email': 'thai.mb@icloud.com',
              'givenName': 'Thai',
              'familyName': 'Mai',
              'identityToken': 'mock_identity_token',
              'authorizationCode': 'mock_auth_code',
              'userIdentifier': 'apple_user_123',
            };
          }
          return null;
        },
      );
    });

    test('signInWithApple links credential if current user is anonymous', () async {
      // Setup anonymous current user
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.linkWithCredential(any())).thenAnswer((_) async => UserCredentialFake(mockUser));

      // Create provider
      authProvider = AuthProvider(
        auth: mockAuth,
        googleSignIn: mockGoogleSignIn,
        migrationService: fakeMigrationService,
      );

      // Trigger Apple Sign-In
      await authProvider.signInWithApple();

      // Verify linkWithCredential was called on the mockUser
      verify(() => mockUser.linkWithCredential(any())).called(1);
      // Verify signInWithCredential was NOT called
      verifyNever(() => mockAuth.signInWithCredential(any()));
    });

    test('signInWithApple signs in directly if no user is logged in', () async {
      // No current user
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) async => UserCredentialFake(mockUser));

      authProvider = AuthProvider(
        auth: mockAuth,
        googleSignIn: mockGoogleSignIn,
        migrationService: fakeMigrationService,
      );

      await authProvider.signInWithApple();

      // Verify signInWithCredential was called on FirebaseAuth
      verify(() => mockAuth.signInWithCredential(any())).called(1);
    });

    test('signInWithAppleDirectly signs in directly even if an anonymous user exists', () async {
      // Current user is anonymous
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) async => UserCredentialFake(mockUser));

      authProvider = AuthProvider(
        auth: mockAuth,
        googleSignIn: mockGoogleSignIn,
        migrationService: fakeMigrationService,
      );

      await authProvider.signInWithAppleDirectly();

      // Verify signInWithCredential was called on FirebaseAuth directly
      verify(() => mockAuth.signInWithCredential(any())).called(1);
      // Verify linkWithCredential was NOT called on the mockUser
      verifyNever(() => mockUser.linkWithCredential(any()));
    });
  });
}

// Simple dummy class implementing UserCredential
class UserCredentialFake extends Fake implements UserCredential {
  final User? _user;
  UserCredentialFake([this._user]);

  @override
  User? get user => _user;
}
