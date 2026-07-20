import Flutter
import FirebaseCore
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Only configure Firebase natively when GoogleService-Info.plist is present.
    // Without this guard, `FirebaseApp.configure()` throws an uncaught exception
    // and crashes the app on launch when the plist hasn't been added yet.
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
