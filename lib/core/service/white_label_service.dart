import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/white_label_data.dart';
import 'api_service.dart';

/// Institute branding (name, splash logo, institute logo) the admin sets on
/// the White Label page.
///
/// Rules this follows (see `GET white-label`):
///  * Public endpoint: called without the auth header, before login.
///  * The app draws at once from the cached copy — or, on a first install,
///    from the built-in branding — and is never blocked on this call.
///  * Re-checks send the cached `ETag`; a `304` keeps the cached copy.
///  * `503` / no network keeps the cached copy (it is not "nothing set").
///  * A new image always gets a new URL, so images are saved to disk by URL
///    and kept forever; the splash shows the logo even when offline.
class WhiteLabelService {
  WhiteLabelService._();

  static final WhiteLabelService instance = WhiteLabelService._();

  static const String endpoint = 'white-label';
  static const String _prefsDataKey = 'white_label_data';
  static const String _prefsEtagKey = 'white_label_etag';

  final ValueNotifier<WhiteLabelData> data = ValueNotifier<WhiteLabelData>(
    WhiteLabelData.defaults,
  );

  bool _isLoaded = false;
  Future<void>? _inFlight;
  Directory? _imageDir;
  final Map<String, Future<void>> _downloads = {};

  /// Loads the cached copy from disk. Called once at startup, before the
  /// first frame, so the splash never flashes the built-in logo over the
  /// institute's.
  Future<void> init() async {
    if (_isLoaded) return;
    _isLoaded = true;
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/white_label');
      if (!await dir.exists()) await dir.create(recursive: true);
      _imageDir = dir;
    } catch (e) {
      debugPrint('WhiteLabelService: image dir unavailable -> $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsDataKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          data.value = WhiteLabelData.fromJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('WhiteLabelService: cache read failed -> $e');
    }
    _cacheImages(data.value);
  }

  /// Fetches the current branding. Never awaited on a critical path.
  Future<void> refresh() {
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  /// The saved copy of [url], or `null` while it isn't downloaded yet.
  File? localFile(String url) {
    final dir = _imageDir;
    if (dir == null) return null;
    final file = File('${dir.path}/${_fileNameFor(url)}');
    return file.existsSync() ? file : null;
  }

  Future<void> _fetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final etag = prefs.getString(_prefsEtagKey);
      final hasCache = (prefs.getString(_prefsDataKey) ?? '').isNotEmpty;

      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}$endpoint'),
            headers: {
              'Accept': 'application/json',
              // Only send the ETag when the copy it belongs to is still saved.
              if (etag != null && etag.isNotEmpty && hasCache)
                'If-None-Match': etag,
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 304) return;
      if (response.statusCode != 200) {
        debugPrint(
          'WhiteLabelService: keeping cached branding '
          '(${response.statusCode})',
        );
        return;
      }

      final body = jsonDecode(response.body);
      final payload = body is Map ? body['data'] : null;
      if (payload is! Map) return;

      final next = WhiteLabelData.fromJson(
        payload.map((key, value) => MapEntry(key.toString(), value)),
      );
      final encoded = jsonEncode(next.toJson());

      await prefs.setString(_prefsDataKey, encoded);
      final newEtag = response.headers['etag'];
      if (newEtag != null && newEtag.isNotEmpty) {
        await prefs.setString(_prefsEtagKey, newEtag);
      } else {
        await prefs.remove(_prefsEtagKey);
      }

      _cacheImages(next);
      // Redraw only when something actually changed.
      if (encoded != jsonEncode(data.value.toJson())) {
        data.value = next;
      }
    } catch (e) {
      debugPrint('WhiteLabelService: fetch failed -> $e');
    }
  }

  /// Saves the splash and institute logos to disk. Failures are ignored; the
  /// widget shows the network image (or the bundled logo) meanwhile.
  void _cacheImages(WhiteLabelData value) {
    for (final image in [value.splashLogo, value.instituteLogo]) {
      if (image == null || localFile(image.url) != null) continue;
      _downloads.putIfAbsent(
        image.url,
        () => _download(
          image.url,
        ).whenComplete(() => _downloads.remove(image.url)),
      );
    }
  }

  Future<void> _download(String url) async {
    final dir = _imageDir;
    if (dir == null) return;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return;
      final target = File('${dir.path}/${_fileNameFor(url)}');
      // Written under a temp name so a half-written file is never shown.
      final temp = File('${target.path}.part');
      await temp.writeAsBytes(response.bodyBytes, flush: true);
      await temp.rename(target.path);
    } catch (e) {
      debugPrint('WhiteLabelService: image download failed $url -> $e');
    }
  }

  /// A file name unique per URL (each new image has a new URL).
  String _fileNameFor(String url) {
    final uri = Uri.tryParse(url);
    final last = (uri?.pathSegments.isNotEmpty ?? false)
        ? uri!.pathSegments.last
        : '';
    final safe = last.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return '${_stableHash(url)}_$safe';
  }

  /// FNV-1a: unlike `String.hashCode`, the same on every launch.
  String _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode(input)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
