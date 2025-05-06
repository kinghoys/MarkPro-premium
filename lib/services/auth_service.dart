import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create test user
  Future<UserCredential> createTestUser() async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: 'test@markproplus.com',
        password: '123456',
      );
      
      // Create user document in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': 'Test User',
        'email': 'test@markproplus.com',
        'role': 'faculty',
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Test user creation error: ${e.message}');
      }
      throw e;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Login error: ${e.message}');
      }
      throw e;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Registration error: ${e.message}');
      }
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      throw e;
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Password reset error: ${e.message}');
      }
      throw e;
    }
  }
}
