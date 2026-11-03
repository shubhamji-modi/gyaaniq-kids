import Flutter
import FirebaseCore
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications / firebase_messaging receive and show
    // notifications while the app is in the foreground.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

    // Configure before the plugins register, and only once: the FlutterFire
    // plugins configure the default app themselves too, and a second
    // `FirebaseApp.configure()` throws "Default app has already been
    // configured" and crashes on launch. Also skipped when the plist is
    // missing, where configure() would throw as well.
    if FirebaseApp.app() == nil,
       Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
