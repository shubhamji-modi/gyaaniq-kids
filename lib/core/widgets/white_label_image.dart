import 'dart:io';

import 'package:flutter/material.dart';

import '../models/white_label_data.dart';
import '../service/white_label_service.dart';

/// An image from the White Label page.
///
/// Draws the saved copy when there is one, otherwise the network image. While
/// it loads — or when [image] is `null` or fails — [fallback] is shown, so the
/// screen never shows a broken image.
class WhiteLabelImageView extends StatelessWidget {
  const WhiteLabelImageView({
    super.key,
    required this.image,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  final WhiteLabelImage? image;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = image?.url;
    if (url == null) return fallback;

    Widget frame(BuildContext context, Widget child, int? frame, bool sync) {
      if (sync || frame != null) return child;
      return fallback;
    }

    Widget error(BuildContext context, Object error, StackTrace? stack) {
      debugPrint('WhiteLabelImageView: $url failed -> $error');
      return fallback;
    }

    final File? file = WhiteLabelService.instance.localFile(url);
    if (file != null) {
      return Image.file(
        file,
        fit: fit,
        frameBuilder: frame,
        errorBuilder: (context, e, stack) => Image.network(
          url,
          fit: fit,
          frameBuilder: frame,
          errorBuilder: error,
        ),
      );
    }
    return Image.network(
      url,
      fit: fit,
      frameBuilder: frame,
      errorBuilder: error,
    );
  }
}
