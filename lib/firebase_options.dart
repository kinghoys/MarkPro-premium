import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Handle other platforms if needed
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDFPptnUqciyN3HsA-f03xDz6aXxNvZrXg',
    appId: '1:304107012618:web:1c91894bf03a5b27f455f3',
    messagingSenderId: '304107012618',
    projectId: 'markpro-plus',
    authDomain: 'markpro-plus.firebaseapp.com',
    databaseURL: 'https://markpro-plus-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'markpro-plus.firebasestorage.app',
    measurementId: 'G-VX5QTTNP68',
  );
}
