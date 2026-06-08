import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'session_manager.dart';

enum OfflineDownloadType { video, pdf }

class OfflineDownloadService {
  OfflineDownloadService._();

  static final OfflineDownloadService instance = OfflineDownloadService._();

  static const String _storageKey = 'offline_download_items';

  Future<List<OfflineDownloadItem>> getItems() async {
    final preferences = await SharedPreferences.getInstance();
    final rawItems = preferences.getStringList(_storageKey) ?? const <String>[];
    final items = rawItems
        .map((raw) {
          try {
            return OfflineDownloadItem.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<OfflineDownloadItem>()
        .where((item) => File(item.localPath).existsSync())
        .toList();

    items.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    return items;
  }

  Future<bool> isDownloaded({
    required String sourceId,
    required OfflineDownloadType type,
  }) async {
    final items = await getItems();
    return items.any((item) => item.sourceId == sourceId && item.type == type);
  }

  Future<OfflineDownloadItem> download({
    required String sourceId,
    required String title,
    required String sectionTitle,
    required String badge,
    required String sourceUrl,
    required OfflineDownloadType type,
    Map<String, String> headers = const {},
    void Function(int received, int total)? onProgress,
  }) async {
    final existing = await _findItem(sourceId: sourceId, type: type);
    if (existing != null && File(existing.localPath).existsSync()) {
      return existing;
    }

    final directory = await _downloadDirectory();
    final candidateUrls = _candidateUrls(sourceUrl);
    final resolvedUrl = candidateUrls.first;
    final fileName = _fileName(sourceId, resolvedUrl, type);
    final file = File('${directory.path}/$fileName');
    final requestHeaders = <String, String>{
      ...headers,
      if (_userToken.isNotEmpty) 'Authorization': 'Bearer $_userToken',
    };

    http.Response? response;
    Object? lastError;
    String successfulUrl = resolvedUrl;

    for (final url in candidateUrls) {
      try {
        response = await _getUrl(url, requestHeaders);
        successfulUrl = url;
        break;
      } catch (error) {
        lastError = error;
        if (requestHeaders.containsKey('Authorization')) {
          try {
            final headersWithoutAuth = Map<String, String>.from(requestHeaders)
              ..remove('Authorization');
            response = await _getUrl(url, headersWithoutAuth);
            successfulUrl = url;
            break;
          } catch (retryError) {
            lastError = retryError;
          }
        }
      }
    }

    if (response == null) {
      throw Exception(lastError ?? 'No response from server');
    }

    await file.writeAsBytes(response.bodyBytes, flush: true);
    onProgress?.call(response.bodyBytes.length, response.bodyBytes.length);

    final sizeBytes = await file.length();
    if (sizeBytes == 0) {
      await file.delete();
      throw Exception('Downloaded file is empty');
    }

    final item = OfflineDownloadItem(
      id: '${type.name}_$sourceId',
      sourceId: sourceId,
      title: title,
      sectionTitle: sectionTitle,
      badge: badge,
      sourceUrl: successfulUrl,
      localPath: file.path,
      type: type,
      sizeBytes: sizeBytes,
      downloadedAt: DateTime.now(),
    );

    await _upsertItem(item);
    return item;
  }

  Future<void> deleteItem(OfflineDownloadItem item) async {
    final file = File(item.localPath);
    if (await file.exists()) {
      await file.delete();
    }

    final items = await getItems();
    items.removeWhere((entry) => entry.id == item.id);
    await _saveItems(items);
  }

  Future<void> clearAll() async {
    final items = await getItems();
    for (final item in items) {
      final file = File(item.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _saveItems(const <OfflineDownloadItem>[]);
  }

  Future<OfflineDownloadItem?> _findItem({
    required String sourceId,
    required OfflineDownloadType type,
  }) async {
    final items = await getItems();
    for (final item in items) {
      if (item.sourceId == sourceId && item.type == type) {
        return item;
      }
    }
    return null;
  }

  Future<void> _upsertItem(OfflineDownloadItem item) async {
    final items = await getItems();
    items.removeWhere((entry) => entry.id == item.id);
    items.add(item);
    await _saveItems(items);
  }

  Future<void> _saveItems(List<OfflineDownloadItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      items.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<Directory> _downloadDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/offline_downloads');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _fileName(
    String sourceId,
    String sourceUrl,
    OfflineDownloadType type,
  ) {
    final uri = Uri.tryParse(sourceUrl);
    final pathName = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : sourceId;
    final extension = _extension(pathName, type);
    final safeId = sourceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${type.name}_$safeId$extension';
  }

  String _extension(String pathName, OfflineDownloadType type) {
    final dotIndex = pathName.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < pathName.length - 1) {
      final candidate = pathName.substring(dotIndex).split('?').first;
      if (candidate.length <= 8) {
        return candidate;
      }
    }
    return type == OfflineDownloadType.pdf ? '.pdf' : '.mp4';
  }

  String get _userToken {
    try {
      return SessionManager.instance.userToken;
    } catch (_) {
      return '';
    }
  }

  Future<http.Response> _getUrl(String url, Map<String, String> headers) async {
    final uri = Uri.parse(Uri.encodeFull(url));
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode} for $url');
    }
    return response;
  }

  List<String> _candidateUrls(String sourceUrl) {
    final trimmed = sourceUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return [trimmed];
    }
    if (uri.hasScheme) {
      return [trimmed];
    }

    final base = Uri.parse(ApiService.baseUrl);
    final rootBase = base.replace(path: '/', query: '', fragment: '');
    return {
      base.resolve(trimmed).toString(),
      rootBase
          .resolve(trimmed.startsWith('/') ? trimmed.substring(1) : trimmed)
          .toString(),
      if (trimmed.startsWith('/')) base.replace(path: trimmed).toString(),
    }.toList();
  }
}

class OfflineDownloadItem {
  const OfflineDownloadItem({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.sectionTitle,
    required this.badge,
    required this.sourceUrl,
    required this.localPath,
    required this.type,
    required this.sizeBytes,
    required this.downloadedAt,
  });

  final String id;
  final String sourceId;
  final String title;
  final String sectionTitle;
  final String badge;
  final String sourceUrl;
  final String localPath;
  final OfflineDownloadType type;
  final int sizeBytes;
  final DateTime downloadedAt;

  int get sizeMb => (sizeBytes / (1024 * 1024)).ceil();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'title': title,
      'sectionTitle': sectionTitle,
      'badge': badge,
      'sourceUrl': sourceUrl,
      'localPath': localPath,
      'type': type.name,
      'sizeBytes': sizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory OfflineDownloadItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString();
    return OfflineDownloadItem(
      id: json['id']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Downloaded File',
      sectionTitle: json['sectionTitle']?.toString() ?? 'Downloads',
      badge: json['badge']?.toString() ?? 'OFFLINE',
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      localPath: json['localPath']?.toString() ?? '',
      type: OfflineDownloadType.values.firstWhere(
        (entry) => entry.name == typeName,
        orElse: () => OfflineDownloadType.pdf,
      ),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      downloadedAt:
          DateTime.tryParse(json['downloadedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
