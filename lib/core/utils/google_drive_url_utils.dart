String? googleDriveFileId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  if (!host.endsWith('drive.google.com') && !host.endsWith('docs.google.com')) {
    return null;
  }

  final segments = uri.pathSegments;
  final fileIndex = segments.indexOf('d');
  if (fileIndex >= 0 && fileIndex + 1 < segments.length) {
    final id = segments[fileIndex + 1].trim();
    if (id.isNotEmpty) return id;
  }

  final idFromQuery = uri.queryParameters['id']?.trim();
  if (idFromQuery != null && idFromQuery.isNotEmpty) return idFromQuery;

  return null;
}

String pdfDownloadUrl(String url) {
  final id = googleDriveFileId(url);
  if (id == null) return url.trim();
  return Uri.https('drive.google.com', '/uc', {
    'export': 'download',
    'id': id,
  }).toString();
}

String pdfPreviewUrl(String url) {
  final id = googleDriveFileId(url);
  if (id == null) return url.trim();
  return Uri.https('drive.google.com', '/file/d/$id/preview').toString();
}

bool looksLikePdfBytes(List<int> bytes) {
  if (bytes.length < 4) return false;
  return bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}

bool isHtmlResponse(Map<String, String> headers) {
  final contentType = headers['content-type'] ?? headers['Content-Type'] ?? '';
  return contentType.toLowerCase().contains('text/html');
}
