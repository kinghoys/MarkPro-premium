// Firebase configuration file for MarkPro+ Sessions
// This file contains the Firebase configuration details

import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Firebase initialization method
Future<void> initializeFirebase() async {
  try {
    if (kIsWeb) {
      // Web-specific initialization
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDFPptnUqciyN3HsA-f03xDz6aXxNvZrXg',
          authDomain: 'markpro-plus.firebaseapp.com',
          projectId: 'markpro-plus',
          storageBucket: 'markpro-plus.firebasestorage.app',
          messagingSenderId: '304107012618',
          appId: '1:304107012618:web:1c91894bf03a5b27f455f3',
          measurementId: 'G-VX5QTTNP68',
          databaseURL: 'https://markpro-plus-default-rtdb.asia-southeast1.firebasedatabase.app',
        ),
      );
    } else {
      // Mobile initialization
      await Firebase.initializeApp();
    }
    
    // Initialize analytics after Firebase is initialized
    // Analytics code commented out until dependency is added
    /*
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.logAppOpen();
      print('Firebase Analytics initialized successfully');
    } catch (e) {
      print('Analytics error: $e');
      // Continue execution even if analytics fails
    }
    */
    
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
    // For development purposes, we'll allow the app to continue even if Firebase fails
  }
}
