import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String _mapErrorCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address provided is invalid. Please enter a valid email.';
      case 'user-not-found':
        return 'No account found with this email address. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please log in instead.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment before trying again.';
      default:
        return 'Something went wrong. Please try again later.';
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _mapErrorCode(e.code),
      );
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        message: _mapErrorCode(e.code),
      );
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _mapErrorCode(e.code),
      );
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        message: _mapErrorCode(e.code),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _mapErrorCode(e.code),
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _mapErrorCode(e.code),
      );
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        message: _mapErrorCode(e.code),
      );
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _mapErrorCode(e.code),
      );
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        message: _mapErrorCode(e.code),
      );
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently logged in.',
        );
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: e.code,
          message:
              'This action requires recent authentication. Please log out and log in again before deleting your account.',
        );
      }
      throw FirebaseAuthException(
        code: e.code,
        message: _mapErrorCode(e.code),
      );
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        message: _mapErrorCode(e.code),
      );
    }
  }

  User? currentUser() {
    return _auth.currentUser;
  }

  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  bool isEmailVerified() {
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  Future<void> sendVerification() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently logged in.',
        );
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _mapErrorCode(e.code),
      );
    }
  }

  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently logged in.',
        );
      }

      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _mapErrorCode(e.code),
      );
    }
  }

  Stream<User?> authState() {
    return _auth.authStateChanges();
  }
}