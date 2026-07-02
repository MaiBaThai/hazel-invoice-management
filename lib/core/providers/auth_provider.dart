import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:nms/data/services/migration_service.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final MigrationService _migrationService;
  User? _user;
  bool _isInitializing = true;
  bool _hasError = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;
  bool get isInitializing => _isInitializing;
  bool get hasError => _hasError;
  MigrationService get migrationService => _migrationService;

  AuthProvider({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    MigrationService? migrationService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _migrationService = migrationService ?? MigrationService() {
    _user = _auth.currentUser;
    if (_user != null) {
      _isInitializing = false;
    }
    
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isInitializing = false;
      notifyListeners();
    });
  }

  // Migration is now manual via Admin Panel


  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        // If the user is currently anonymous, we should try to link the account
        if (_user != null && _user!.isAnonymous) {
          final userCredential = await _user!.linkWithPopup(googleProvider);
          await _auth.currentUser?.reload();
          _user = userCredential.user ?? _auth.currentUser;
          notifyListeners();
        } else {
          await _auth.signInWithPopup(googleProvider);
        }
        return;
      }

      // Mobile logic
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      if (_user != null && _user!.isAnonymous) {
        final userCredential = await _user!.linkWithCredential(credential);
        await _auth.currentUser?.reload();
        _user = userCredential.user ?? _auth.currentUser;
        notifyListeners();
      } else {
        await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  /// Forces a fresh Google Sign-In, ignoring the current anonymous user.
  /// Useful when the Google account is already linked to another UID.
  Future<void> signInWithGoogleDirectly() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        // Use setCustomParameters to force account selection if needed
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        await _auth.signInWithPopup(googleProvider);
        return;
      }

      // Mobile logic
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Direct login failed: $e');
      rethrow;
    }
  }

  /// Silently signs in anonymously if no user is currently logged in.
  Future<void> signInSilently() async {
    _hasError = false;
    notifyListeners();
    
    try {
      if (kIsWeb) {
        if (_auth.currentUser == null) {
          await _auth.signInAnonymously();
        } else {
          _user = _auth.currentUser;
          _isInitializing = false;
          notifyListeners();
        }
        return;
      }

      // Mobile logic
      final Future<GoogleSignInAccount?>? authFuture = _googleSignIn.attemptLightweightAuthentication();
      final GoogleSignInAccount? googleUser = authFuture != null
          ? await authFuture.timeout(const Duration(seconds: 2), onTimeout: () => null)
          : null;
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      } else if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      } else {
        _user = _auth.currentUser;
        _isInitializing = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      _isInitializing = false;
      _hasError = true;
      notifyListeners();
      
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
        } catch (ae) {
          debugPrint('Anonymous fallback failed: $ae');
          _hasError = true;
          notifyListeners();
        }
      }
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      rethrow;
    }
  }

  /// Generates a cryptographically secure random nonce.
  String _generateNonce([int length = 32]) {
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-_';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final AuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // If the current user is anonymous, we link the accounts to keep their data
      if (_user != null && _user!.isAnonymous) {
        final userCredential = await _user!.linkWithCredential(credential);
        await _auth.currentUser?.reload();
        _user = userCredential.user ?? _auth.currentUser;
        notifyListeners();
      } else {
        await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Apple login failed: $e');
      rethrow;
    }
  }

  /// Forces a fresh Apple Sign-In, ignoring the current anonymous user.
  /// Useful when the Apple account is already linked to another UID.
  Future<void> signInWithAppleDirectly() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final AuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Direct Apple login failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    _hasError = false;
    notifyListeners();
    
    await _auth.signOut();
    
    // Google sign-out is triggered in the background so it doesn't block the UI/flow if it hangs
    _googleSignIn.signOut().catchError((e) {
      debugPrint('Google Sign-Out failed: $e');
      return null;
    });
  }

  /// Deletes the authenticated user's Firestore data first, then deletes their Firebase Auth account.
  /// If the session is stale, Firebase Auth will throw a [FirebaseAuthException] with code 'requires-recent-login'.
  Future<void> deleteCurrentUserAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 1. Delete data from Firestore/Storage first (requires active credentials under security rules)
    await _migrationService.deleteUserScopedData(currentUser.uid);

    // 2. Delete the user account in Firebase Auth
    await currentUser.delete();

    // 3. Perform local logout / cleanup
    await signOut();

    // 4. Reset to anonymous session fallback
    await signInSilently();
  }

  /// Re-authenticates the current user based on their provider (Apple or Google).
  /// This is used to satisfy the security requirement for sensitive operations like account deletion.
  Future<void> reauthenticateCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user currently signed in.');

    final providerIds = user.providerData.map((info) => info.providerId).toList();

    if (providerIds.contains('apple.com')) {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      await user.reauthenticateWithCredential(credential);
    } else if (providerIds.contains('google.com')) {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        await user.reauthenticateWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } else {
      debugPrint('No supported oauth provider found for re-authentication.');
    }
  }
}
