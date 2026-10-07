import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Why getting photos failed, worded for the student.
class LibraryPhotoException implements Exception {
  const LibraryPhotoException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Captures lesson pages and gets them ready for upload.
///
/// Reading quality depends far more on the photo than on anything else, so
/// pages come from the platform document scanner (ML Kit on Android, VisionKit
/// on iOS) which finds the page edges, straightens and cleans the shot. Every
/// photo is then resized to ~[targetLongEdge] px on the long side and saved as
/// JPEG ~[jpegQuality] — that also turns an iPhone HEIC into a JPEG, which the
/// server needs.
class LibraryPhotoService {
  const LibraryPhotoService._();

  static const int targetLongEdge = 1600;
  static const int jpegQuality = 80;

  /// Opens the document scanner for up to [maxPages] pages. Returns the
  /// prepared JPEG paths in scan order, or an empty list when cancelled.
  static Future<List<String>> scanPages({int maxPages = 30}) async {
    final List<String>? raw;
    try {
      raw = await CunningDocumentScanner.getPictures(
        noOfPages: math.max(1, maxPages),
        scannerSource: ScannerSource.camera,
        iosScannerOptions: IosScannerOptions(
          imageFormat: IosImageFormat.jpg,
          jpgCompressionQuality: 0.9,
        ),
      );
    } on CunningDocumentScannerException catch (e) {
      if (e.code == 'permission_denied') {
        throw const LibraryPhotoException(
          'Camera permission is needed to scan the pages. '
          'Please allow it in Settings.',
        );
      }
      throw LibraryPhotoException(
        e.message.isEmpty ? 'The scanner could not start.' : e.message,
      );
    } catch (e) {
      debugPrint('LibraryPhotoService: scanner failed -> $e');
      throw const LibraryPhotoException('The scanner could not start.');
    }
    if (raw == null || raw.isEmpty) return const [];
    return _prepareAll(raw);
  }

  /// Fallback for pages that are already photographed: pick from the gallery.
  static Future<List<String>> pickFromGallery({int maxPages = 30}) async {
    final picker = ImagePicker();
    final List<XFile> files;
    try {
      files = maxPages <= 1
          ? [?await picker.pickImage(source: ImageSource.gallery)]
          : await picker.pickMultiImage(limit: math.max(2, maxPages));
    } catch (e) {
      debugPrint('LibraryPhotoService: gallery failed -> $e');
      throw const LibraryPhotoException('Could not open your photos.');
    }
    if (files.isEmpty) return const [];
    return _prepareAll(files.take(maxPages).map((f) => f.path).toList());
  }

  static Future<List<String>> _prepareAll(List<String> paths) async {
    final out = <String>[];
    for (final path in paths) {
      out.add(await prepare(path));
    }
    return out;
  }

  /// Resizes [sourcePath] to ~1600 px on the long side as a JPEG. Falls back
  /// to the original file only when it already is a JPEG/PNG/WebP — never
  /// sends a HEIC.
  static Future<String> prepare(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/library_page_${DateTime.now().microsecondsSinceEpoch}.jpg';

    // flutter_image_compress keeps the image's aspect ratio and scales by the
    // *smaller* of width/minWidth and height/minHeight, so asking for the
    // proportional size gives exactly targetLongEdge on the long side.
    var minWidth = targetLongEdge;
    var minHeight = targetLongEdge;
    final size = await _rawSize(sourcePath);
    if (size != null && size.longEdge > 0) {
      final scale = targetLongEdge / size.longEdge;
      minWidth = math.max(1, (size.width * scale).round());
      minHeight = math.max(1, (size.height * scale).round());
    }

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        target,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: jpegQuality,
        format: CompressFormat.jpeg,
      );
      if (result != null && await File(result.path).exists()) {
        return result.path;
      }
    } catch (e) {
      debugPrint('LibraryPhotoService: compress failed -> $e');
    }

    final lower = sourcePath.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return sourcePath;
    }
    throw const LibraryPhotoException(
      'This photo could not be prepared. Please take it again.',
    );
  }

  /// Pixel size as stored in the file (before EXIF rotation, which is also
  /// what the compressor scales against). Read from the header only — the
  /// image is not decoded.
  static Future<({int width, int height, int longEdge})?> _rawSize(
    String path,
  ) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromFilePath(path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final w = descriptor.width;
      final h = descriptor.height;
      return (width: w, height: h, longEdge: math.max(w, h));
    } catch (_) {
      return null;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  /// Removes scanner leftovers. Safe to call any time.
  static Future<void> cleanUp() async {
    try {
      await CunningDocumentScanner.cleanCache();
    } catch (_) {}
  }
}
