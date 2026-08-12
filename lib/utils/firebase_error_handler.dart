import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorHandler {
  static String getMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address';
        case 'user-disabled':
          return 'This user has been disabled. Please contact support.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'operation-not-allowed':
          return 'This operation is not allowed. Please contact support.';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Unable to complete the request. Please try again.';
      }
    }
    return 'Unable to complete the request. Please try again.';
  }
}
