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
