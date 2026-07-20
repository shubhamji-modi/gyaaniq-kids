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
        // iOS still holds placeholder values (no real GoogleService-Info.plist
        // yet). Throwing here — inside the guarded init in main() — lets the app
        // launch with Firebase disabled on iOS instead of passing an invalid
        // GOOGLE_APP_ID to the native SDK, which would raise an uncatchable
        // NSException and crash on launch. Remove this guard once real iOS
        // values are filled in below.
        if (ios.appId == 'IOS_APP_ID') {
          throw UnsupportedError(
            'Firebase iOS is not configured yet. Add '
            'ios/Runner/GoogleService-Info.plist and replace the placeholder '
            'iOS values in firebase_options.dart (run `flutterfire configure`).',
          );
        }
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
    iosBundleId: 'com.gyaaniqkids.app',
  );
}
