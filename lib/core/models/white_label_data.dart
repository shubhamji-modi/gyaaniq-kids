/// One image the admin uploaded on the White Label page.
class WhiteLabelImage {
  const WhiteLabelImage({
    required this.url,
    this.width,
    this.height,
    this.mimeType,
  });

  final String url;
  final int? width;
  final int? height;
  final String? mimeType;

  /// Width / height, or `null` when the server didn't send both.
  double? get aspectRatio {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }

  /// `null` for a missing / removed image, so callers fall back to the
  /// bundled one.
  static WhiteLabelImage? fromJson(dynamic json) {
    if (json is! Map) return null;
    final url = json['url']?.toString().trim() ?? '';
    if (url.isEmpty) return null;
    return WhiteLabelImage(
      url: url,
      width: _toInt(json['width']),
      height: _toInt(json['height']),
      mimeType: json['mimeType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'width': width,
    'height': height,
    'mimeType': mimeType,
  };

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// Institute branding from `GET white-label`. Every field can be `null`: that
/// item falls back to the app's built-in branding.
class WhiteLabelData {
  const WhiteLabelData({
    this.configured = false,
    this.instituteName,
    this.splashLogo,
    this.instituteLogo,
    this.appIcon,
    this.updatedAt,
  });

  static const WhiteLabelData defaults = WhiteLabelData();

  /// Shown wherever the admin hasn't set an institute name.
  static const String bundledName = 'GyaanIQ';

  final bool configured;
  final String? instituteName;
  final WhiteLabelImage? splashLogo;
  final WhiteLabelImage? instituteLogo;
  final WhiteLabelImage? appIcon;
  final String? updatedAt;

  /// The admin's name, or the built-in one.
  String get displayName => instituteName ?? bundledName;

  /// True when there is something of the institute's own to show.
  bool get hasInstituteBranding =>
      configured && (instituteName != null || instituteLogo != null);

  factory WhiteLabelData.fromJson(Map<String, dynamic> json) {
    final configured = json['configured'] == true;
    if (!configured) return defaults;
    final name = json['instituteName']?.toString().trim() ?? '';
    return WhiteLabelData(
      configured: true,
      instituteName: name.isEmpty ? null : name,
      splashLogo: WhiteLabelImage.fromJson(json['splashLogo']),
      instituteLogo: WhiteLabelImage.fromJson(json['instituteLogo']),
      appIcon: WhiteLabelImage.fromJson(json['appIcon']),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'configured': configured,
    'instituteName': instituteName,
    'splashLogo': splashLogo?.toJson(),
    'instituteLogo': instituteLogo?.toJson(),
    'appIcon': appIcon?.toJson(),
    'updatedAt': updatedAt,
  };
}
