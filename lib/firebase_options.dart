import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform yet.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzDvKDl0yPOaghRIWEBq7Lab0ZNR2KoUU',
    appId: '1:924071318406:android:7fcaa628a83bc4103b9207',
    messagingSenderId: '924071318406',
    projectId: 'hobbylab-adae9',
    storageBucket: 'hobbylab-adae9.firebasestorage.app',
  );
}
