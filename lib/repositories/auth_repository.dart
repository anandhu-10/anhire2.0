import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
      FirebaseAuth.instance,
    ));

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  bool _isGoogleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleInitialized && !kIsWeb) {
      await GoogleSignIn.instance.initialize(
        clientId: '708309942572-3vh39e9p0m8ofan76haiqf1gsm1ialp3.apps.googleusercontent.com',
      );
      _isGoogleInitialized = true;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On Web, use Firebase's built-in signInWithPopup which handles the new GIS SDK automatically
        final googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // On Android/iOS, use google_sign_in
        await _ensureGoogleInitialized();
        
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate(
          scopeHint: ['email', 'profile'],
        );

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e, stack) {
      print('Google Sign-In Error: $e');
      print(stack);
      // Rethrow so the AuthController can catch it and show a SnackBar in the UI
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    final trimmed = email.trim();
    debugPrint("AuthRepository.resetPassword called for email: '$trimmed'");
    await _auth.sendPasswordResetEmail(email: trimmed);
  }
}
