import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAscOtAgkz5Knk6pxueHGYGRYUswGtMdqE',
    appId: '1:333099637813:web:8f117c86ae2ad395cbe57c',
    messagingSenderId: '333099637813',
    projectId: 'paw-adoptar-df4a5',
    authDomain: 'paw-adoptar-df4a5.firebaseapp.com',
    storageBucket: 'paw-adoptar-df4a5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMp3ACt5cxridnn_E7n0vzJ8jWdX82m34',
    appId: '1:333099637813:android:204c8fbd5c70e94ccbe57c',
    messagingSenderId: '333099637813',
    projectId: 'paw-adoptar-df4a5',
    storageBucket: 'paw-adoptar-df4a5.firebasestorage.app',
  );
}
