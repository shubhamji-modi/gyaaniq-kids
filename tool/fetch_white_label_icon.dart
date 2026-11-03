// Downloads the institute's app icon (White Label page) into
// assets/icon/ so flutter_launcher_icons can build it into the app.
//
// Android and iOS don't let an installed app swap its launcher icon for a
// downloaded image, so this runs at build time:
//
//   dart run tool/fetch_white_label_icon.dart
//   dart run flutter_launcher_icons
//   flutter build apk / flutter build ipa
//
// When no icon is set, the current bundled icon is left as it is.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const String _endpoint = 'https://gyaaniqkids.pixelnx.in/api/v1/white-label';

Future<void> main() async {
  final client = HttpClient();
  try {
    final body = await _getJson(client, Uri.parse(_endpoint));
    final data = body['data'];
    final icon = data is Map ? data['appIcon'] : null;
    final url = icon is Map ? icon['url']?.toString() : null;
    if (data is! Map || data['configured'] != true || url == null) {
      stdout.writeln('No white-label app icon set; keeping the bundled one.');
      return;
    }

    final width = icon['width'];
    final height = icon['height'];
    if (width is num && height is num && (width < 512 || width != height)) {
      stderr.writeln(
        'App icon must be square and at least 512px (got ${width}x$height).',
      );
      exitCode = 1;
      return;
    }

    final mime = icon['mimeType']?.toString() ?? '';
    if (!mime.contains('png') &&
        !mime.contains('jpeg') &&
        !mime.contains('jpg')) {
      stderr.writeln('App icon must be PNG or JPG (got "$mime").');
      exitCode = 1;
      return;
    }
    final bytes = await _getBytes(client, Uri.parse(url));

    // pubspec.yaml's flutter_launcher_icons reads these two files.
    await File('assets/icon/app_icon.png').writeAsBytes(bytes, flush: true);
    await File('assets/icon/app_icon1.jpeg').writeAsBytes(bytes, flush: true);
    stdout.writeln(
      'Saved app icon for "${data['instituteName'] ?? '-'}". '
      'Now run: dart run flutter_launcher_icons',
    );
  } catch (e) {
    stderr.writeln('Could not fetch the white-label app icon: $e');
    exitCode = 1;
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> _getJson(HttpClient client, Uri uri) async {
  final bytes = await _getBytes(client, uri);
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Unexpected response');
  }
  return decoded;
}

Future<List<int>> _getBytes(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw HttpException('HTTP ${response.statusCode}', uri: uri);
  }
  final builder = BytesBuilder(copy: false);
  await for (final chunk in response) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
