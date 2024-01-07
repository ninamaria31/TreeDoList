import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
            code: 'empty-fields', message: 'Email and password cannot be empty.');
      }
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      rethrow; // throw the error to be caught in the UI code
    }
  }

  Future<void> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
            code: 'empty-fields', message: 'Email and password cannot be empty.');
      }
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      rethrow; // throw the error to be caught in the UI code
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}