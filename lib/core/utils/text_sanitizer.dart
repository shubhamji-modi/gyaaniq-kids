import 'package:characters/characters.dart';

String sanitizeTextForFlutter(String value) {
  final units = value.codeUnits;
  final buffer = StringBuffer();

  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    final isHighSurrogate = unit >= 0xD800 && unit <= 0xDBFF;
    final isLowSurrogate = unit >= 0xDC00 && unit <= 0xDFFF;

    if (isHighSurrogate) {
      final hasPair =
          i + 1 < units.length &&
          units[i + 1] >= 0xDC00 &&
          units[i + 1] <= 0xDFFF;
      if (hasPair) {
        buffer.writeCharCode(unit);
        buffer.writeCharCode(units[++i]);
      } else {
        buffer.write('\uFFFD');
      }
      continue;
    }

    if (isLowSurrogate) {
      buffer.write('\uFFFD');
      continue;
    }

    buffer.writeCharCode(unit);
  }

  return buffer.toString();
}

dynamic sanitizeApiText(dynamic value) {
  if (value is String) {
    return sanitizeTextForFlutter(value);
  }

  if (value is List) {
    return value.map(sanitizeApiText).toList();
  }

  if (value is Map<String, dynamic>) {
    return value.map(
      (key, mapValue) => MapEntry(key, sanitizeApiText(mapValue)),
    );
  }

  if (value is Map) {
    return value.map(
      (key, mapValue) => MapEntry(key, sanitizeApiText(mapValue)),
    );
  }

  return value;
}

/// Builds avatar initials without ever slicing a surrogate pair.
///
/// `name[0]` on a string that starts with an emoji (or any non-BMP glyph)
/// returns a lone surrogate, which crashes the text engine with
/// "string is not well-formed UTF-16" when Flutter tries to lay it out.
String safeInitials(String name, {String fallback = 'ST'}) {
  final parts = sanitizeTextForFlutter(name)
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return fallback;
  }
  final initials = parts
      .take(2)
      .map((part) => part.characters.first.toUpperCase())
      .join();
  return initials.isEmpty ? fallback : initials;
}

/// Truncates [value] on grapheme boundaries so emoji/combined characters are
/// never cut in half.
String safeTruncate(String value, int maxLength, {String ellipsis = '...'}) {
  final cleaned = sanitizeTextForFlutter(value);
  final characters = cleaned.characters;
  if (characters.length <= maxLength) {
    return cleaned;
  }
  return '${characters.take(maxLength)}$ellipsis';
}
