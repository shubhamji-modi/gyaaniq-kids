// File generated for GyaanIQ Kids Firebase project.
//
// Android values are taken from android/app/google-services.json.
// iOS values are filled once ios/Runner/GoogleService-Info.plist is added
// (run `flutterfire configure` to regenerate this file automatically).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// ```dart
/// import 'firebase_options.dart';
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCdvQPmJoqjEU9p7p2ojhJmrte-9__jMAs',
    appId: '1:792534498801:android:c667452def3d142e8f9850',
    messagingSenderId: '792534498801',
    projectId: 'gyaaniqkids',
    storageBucket: 'gyaaniqkids.firebasestorage.app',
  );

  // TODO: Replace the iOS values below with the ones from
  // ios/Runner/GoogleService-Info.plist (download it from the Firebase console
  // → iOS app), then this returns real config instead of throwing.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'IOS_API_KEY',
    appId: 'IOS_APP_ID',
    messagingSenderId: '792534498801',
    projectId: 'gyaaniqkids',
    storageBucket: 'gyaaniqkids.firebasestorage.app',
    iosBundleId: 'org.gyaaniqkids.ai',
  );
}
