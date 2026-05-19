import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:nms/data/services/migration_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final MigrationService _migrationService = MigrationService();
  User? _user;
  bool _isInitializing = true;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;
  bool get isInitializing => _isInitializing;
  MigrationService get migrationService => _migrationService;

  AuthProvider() {
    _user = _auth.currentUser;
    if (_user != null) _isInitializing = false;
    
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
          await _user!.linkWithPopup(googleProvider);
        } else {
          await _auth.signInWithPopup(googleProvider);
        }
        return;
      }

      // Mobile logic
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      if (_user != null && _user!.isAnonymous) {
        await _user!.linkWithCredential(credential);
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.attemptLightweightAuthentication();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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
      notifyListeners();
      
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
        } catch (ae) {
          debugPrint('Anonymous fallback failed: $ae');
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

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
  }
}
