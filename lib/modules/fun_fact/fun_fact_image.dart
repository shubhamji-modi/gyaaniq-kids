import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Builds the image provider for every fun-fact picture, everywhere.
///
/// Two reasons this exists instead of a bare `NetworkImage`:
///
/// 1. Teacher-uploaded artwork is far larger than a phone screen. A decoded
///    image costs width × height × 4 bytes, so a 3000×3000 upload is 36 MB.
///    Flutter's image cache holds 100 MB by default, evicts down to that, and
///    refuses outright to store a single image bigger than the whole budget —
///    so a handful of full-size fun facts either evict each other or are never
///    cached at all. That is what makes a "preloaded" story arrive cold.
///    Decoding at screen width caps each one near 12 MB, so a batch stays
///    resident.
///
/// 2. The provider *is* the cache key. Precaching with one provider and
///    displaying with a different one silently means two decodes and two
///    downloads. Routing every call site through here keeps the key identical.
///
/// Takes no BuildContext on purpose. `View.of`/`MediaQuery.of` are inherited
/// widget lookups, which are illegal during initState — and the story warms its
/// images from there. Reading the view off the platform dispatcher works from
/// anywhere and yields the same number at every call site, which is exactly
/// what a stable cache key needs.
ImageProvider funFactImage(String url) {
  final targetWidth = ui.PlatformDispatcher.instance.implicitView?.physicalSize
      .width
      .round();
  // No view yet (or a zero-sized one): fall back to the full-size image rather
  // than resizing to nothing.
  if (targetWidth == null || targetWidth <= 0) {
    return NetworkImage(url);
  }
  return ResizeImage(NetworkImage(url), width: targetWidth);
}
