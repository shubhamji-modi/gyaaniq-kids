import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The logo on the Login / Register screens.
///
/// Shows the admin's [logoUrl] when set, otherwise the bundled logo. While the
/// network image loads — or if it fails — the bundled logo is shown instead,
/// so the screen never shows a broken image.
class AuthScreenLogo extends StatelessWidget {
  const AuthScreenLogo({super.key, this.logoUrl, this.fit});

  static const String bundledAsset = 'assets/icon/app_icon.png';

  final String? logoUrl;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final bundled = Image.asset(bundledAsset, fit: fit);
    final url = logoUrl;

    return Container(
      width: 200,
      height: 210,
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        child: url == null
            ? bundled
            : Center(
                // Admin logos are shown square, the size of today's logo.
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    frameBuilder: (context, child, frame, wasSync) {
                      if (wasSync || frame != null) return child;
                      return bundled;
                    },
                    errorBuilder: (context, error, stack) {
                      debugPrint('AuthScreenLogo: $url failed -> $error');
                      return bundled;
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

/// Opens a Terms / Privacy link from the auth screens in an in-app browser,
/// falling back to the external browser.
Future<void> openAuthScreenLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('openAuthScreenLink: could not open $url -> $e');
  }
}
