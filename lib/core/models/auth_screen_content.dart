/// Admin-editable text and logo of the Login and Register screens
/// (`GET app-screens/login`, `GET app-screens/register`).
///
/// Every getter falls back to the bundled default, so a missing or malformed
/// key never blanks a label. Only [logoUrl] and [updatedAt] can be `null`.
/// Text is plain text and is shown exactly as sent — never as HTML.
library;

class AuthFieldText {
  const AuthFieldText({required this.label, required this.placeholder});

  final String label;
  final String placeholder;

  factory AuthFieldText.fromJson(dynamic json, AuthFieldText fallback) {
    final map = _asMap(json);
    return AuthFieldText(
      label: _text(map['label'], fallback.label),
      placeholder: _text(map['placeholder'], fallback.placeholder),
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'placeholder': placeholder};
}

class AuthEmailFieldText extends AuthFieldText {
  const AuthEmailFieldText({
    required this.visible,
    required super.label,
    required super.placeholder,
  });

  /// `false` means: hide the field and never send `email` on register.
  final bool visible;

  factory AuthEmailFieldText.fromJson(
    dynamic json,
    AuthEmailFieldText fallback,
  ) {
    final map = _asMap(json);
    final visible = map['visible'];
    return AuthEmailFieldText(
      visible: visible is bool ? visible : fallback.visible,
      label: _text(map['label'], fallback.label),
      placeholder: _text(map['placeholder'], fallback.placeholder),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'visible': visible, ...super.toJson()};
}

class AuthFooterText {
  const AuthFooterText({
    required this.text,
    required this.termsLinkText,
    required this.termsUrl,
    required this.joinText,
    required this.privacyLinkText,
    required this.privacyUrl,
  });

  final String text;
  final String termsLinkText;
  final String termsUrl;
  final String joinText;
  final String privacyLinkText;
  final String privacyUrl;

  factory AuthFooterText.fromJson(dynamic json, AuthFooterText fallback) {
    final map = _asMap(json);
    return AuthFooterText(
      text: _text(map['text'], fallback.text),
      termsLinkText: _text(map['termsLinkText'], fallback.termsLinkText),
      termsUrl: _url(map['termsUrl'], fallback.termsUrl),
      joinText: _text(map['joinText'], fallback.joinText),
      privacyLinkText: _text(map['privacyLinkText'], fallback.privacyLinkText),
      privacyUrl: _url(map['privacyUrl'], fallback.privacyUrl),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'termsLinkText': termsLinkText,
    'termsUrl': termsUrl,
    'joinText': joinText,
    'privacyLinkText': privacyLinkText,
    'privacyUrl': privacyUrl,
  };
}

class AuthConsentText {
  const AuthConsentText({
    required this.text,
    required this.linkText,
    required this.url,
  });

  final String text;
  final String linkText;
  final String url;

  factory AuthConsentText.fromJson(dynamic json, AuthConsentText fallback) {
    final map = _asMap(json);
    return AuthConsentText(
      text: _text(map['text'], fallback.text),
      linkText: _text(map['linkText'], fallback.linkText),
      url: _url(map['url'], fallback.url),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'linkText': linkText,
    'url': url,
  };
}

class LoginPageData {
  const LoginPageData({
    required this.heading,
    required this.subheading,
    required this.phoneField,
    required this.primaryButtonText,
    required this.dividerText,
    required this.secondaryButtonText,
    required this.footer,
    this.logoUrl,
    this.updatedAt,
  });

  final String heading;

  /// `""` means hide the line.
  final String subheading;
  final AuthFieldText phoneField;
  final String primaryButtonText;

  /// `""` means hide the divider, rules included.
  final String dividerText;
  final String secondaryButtonText;
  final AuthFooterText footer;

  /// `null` means use the logo bundled in the app.
  final String? logoUrl;
  final String? updatedAt;

  /// Bundled copy, equal to what the server sends until an admin edits it.
  static const LoginPageData defaults = LoginPageData(
    heading: 'Welcome Back!',
    subheading: 'Continue your smart learning journey.',
    phoneField: AuthFieldText(
      label: 'MOBILE NUMBER',
      placeholder: 'Enter 10-digit number',
    ),
    primaryButtonText: 'Continue with OTP',
    dividerText: 'OR CONTINUE WITH',
    secondaryButtonText: 'Create new account',
    footer: AuthFooterText(
      text: 'By continuing, you agree to our',
      termsLinkText: 'Terms of Service',
      termsUrl: 'https://gyaaniqkids-portal.pixelnx.in/terms-and-conditions',
      joinText: '&',
      privacyLinkText: 'Privacy Policy',
      privacyUrl: 'https://gyaaniqkids-portal.pixelnx.in/privacy-policy',
    ),
  );

  factory LoginPageData.fromJson(dynamic json) {
    const d = defaults;
    final map = _asMap(json);
    return LoginPageData(
      heading: _text(map['heading'], d.heading),
      subheading: _optionalText(map['subheading'], d.subheading),
      phoneField: AuthFieldText.fromJson(map['phoneField'], d.phoneField),
      primaryButtonText: _text(map['primaryButtonText'], d.primaryButtonText),
      dividerText: _optionalText(map['dividerText'], d.dividerText),
      secondaryButtonText: _text(
        map['secondaryButtonText'],
        d.secondaryButtonText,
      ),
      footer: AuthFooterText.fromJson(map['footer'], d.footer),
      logoUrl: _logo(map['logoUrl']),
      updatedAt: _nullableText(map['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'heading': heading,
    'subheading': subheading,
    'phoneField': phoneField.toJson(),
    'primaryButtonText': primaryButtonText,
    'dividerText': dividerText,
    'secondaryButtonText': secondaryButtonText,
    'footer': footer.toJson(),
    'logoUrl': logoUrl,
    'updatedAt': updatedAt,
  };
}

class RegisterPageData {
  const RegisterPageData({
    required this.heading,
    required this.subheading,
    required this.nameField,
    required this.emailField,
    required this.phoneField,
    required this.consent,
    required this.primaryButtonText,
    required this.dividerText,
    required this.secondaryButtonText,
    this.logoUrl,
    this.updatedAt,
  });

  final String heading;

  /// `""` means hide the line.
  final String subheading;
  final AuthFieldText nameField;
  final AuthEmailFieldText emailField;
  final AuthFieldText phoneField;
  final AuthConsentText consent;
  final String primaryButtonText;

  /// `""` means hide the divider, rules included.
  final String dividerText;
  final String secondaryButtonText;

  /// `null` means use the logo bundled in the app.
  final String? logoUrl;
  final String? updatedAt;

  /// Bundled copy, equal to what the server sends until an admin edits it.
  static const RegisterPageData defaults = RegisterPageData(
    heading: 'Please Enter Your Details to Continue',
    subheading: '',
    nameField: AuthFieldText(label: 'FULL NAME', placeholder: 'Alex Johnson'),
    emailField: AuthEmailFieldText(
      visible: true,
      label: 'EMAIL ADDRESS (OPTIONAL)',
      placeholder: 'alex@school.com',
    ),
    phoneField: AuthFieldText(
      label: 'MOBILE NUMBER',
      placeholder: 'Enter 10-digit number',
    ),
    consent: AuthConsentText(
      text: 'I accept the',
      linkText: 'Privacy Policy',
      url: 'https://gyaaniqkids-portal.pixelnx.in/privacy-policy',
    ),
    primaryButtonText: 'Send OTP',
    dividerText: 'ALREADY HAVE AN ACCOUNT?',
    secondaryButtonText: 'Log in',
  );

  factory RegisterPageData.fromJson(dynamic json) {
    const d = defaults;
    final map = _asMap(json);
    return RegisterPageData(
      heading: _text(map['heading'], d.heading),
      subheading: _optionalText(map['subheading'], d.subheading),
      nameField: AuthFieldText.fromJson(map['nameField'], d.nameField),
      emailField: AuthEmailFieldText.fromJson(map['emailField'], d.emailField),
      phoneField: AuthFieldText.fromJson(map['phoneField'], d.phoneField),
      consent: AuthConsentText.fromJson(map['consent'], d.consent),
      primaryButtonText: _text(map['primaryButtonText'], d.primaryButtonText),
      dividerText: _optionalText(map['dividerText'], d.dividerText),
      secondaryButtonText: _text(
        map['secondaryButtonText'],
        d.secondaryButtonText,
      ),
      logoUrl: _logo(map['logoUrl']),
      updatedAt: _nullableText(map['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'heading': heading,
    'subheading': subheading,
    'nameField': nameField.toJson(),
    'emailField': emailField.toJson(),
    'phoneField': phoneField.toJson(),
    'consent': consent.toJson(),
    'primaryButtonText': primaryButtonText,
    'dividerText': dividerText,
    'secondaryButtonText': secondaryButtonText,
    'logoUrl': logoUrl,
    'updatedAt': updatedAt,
  };
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

/// Required text: anything but a non-empty string keeps the default.
String _text(dynamic value, String fallback) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

/// Text that may legitimately be `""` (hide the line).
String _optionalText(dynamic value, String fallback) {
  if (value is String) return value;
  return fallback;
}

String? _nullableText(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value;
  return null;
}

/// Links are always https per the contract; anything else keeps the default.
String _url(dynamic value, String fallback) {
  if (value is String && value.trim().startsWith('https://')) {
    return value.trim();
  }
  return fallback;
}

String? _logo(dynamic value) {
  if (value is String && value.trim().startsWith('https://')) {
    return value.trim();
  }
  return null;
}
