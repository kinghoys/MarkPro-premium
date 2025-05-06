// Firebase configuration file for MarkPro+ Sessions
// This file contains the Firebase configuration details

import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Firebase initialization method
Future<void> initializeFirebase() async {
  try {
    if (kIsWeb) {
      // Web-specific initialization
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
          authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
          appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
          measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
          databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? '',
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
