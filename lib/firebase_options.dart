import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Firebase.initializeApp.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCn1-eclbvLMJVMtnCICO83mEspjomtCqg',
    appId: '1:535130089179:web:6d5d67820f6626d0234efe',
    messagingSenderId: '535130089179',
    projectId: 'hatly-app-2026',
    authDomain: 'hatly-app-2026.firebaseapp.com',
    storageBucket: 'hatly-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCn1-eclbvLMJVMtnCICO83mEspjomtCqg',
    appId: '1:535130089179:android:6d5d67820f6626d0234efe',
    messagingSenderId: '535130089179',
    projectId: 'hatly-app-2026',
    storageBucket: 'hatly-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC39-B-jbtDejKcBjfZfakzRQejnpFf4tU',
    appId: '1:535130089179:ios:cf34efbe9bf48a4b234efe',
    messagingSenderId: '535130089179',
    projectId: 'hatly-app-2026',
    storageBucket: 'hatly-app-2026.firebasestorage.app',
    iosBundleId: 'com.example.hatly',
  );
}
