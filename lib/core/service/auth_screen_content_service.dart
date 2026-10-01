import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_screen_content.dart';
import 'api_service.dart';

/// Admin-editable content of the Login and Register screens.
///
/// Rules this follows (see `GET app-screens/login` / `app-screens/register`):
///  * The screens draw at once from the cached copy — or, on a first install,
///    from the bundled defaults — and are never blocked on this call.
///  * Both screens are fetched once at launch, and again every time a screen
///    opens (the server caches the answer for ~30s, so this is cheap).
///  * A failed call (`503`, no network) keeps whatever is on screen.
///  * The endpoints are public: they are called without the auth header.
class AuthScreenContentService {
  AuthScreenContentService._();

  static final AuthScreenContentService instance = AuthScreenContentService._();

  static const String _prefsLoginKey = 'login_page_data';
  static const String _prefsRegisterKey = 'register_page_data';

  static const Duration _minRefetchGap = Duration(seconds: 10);

  final ValueNotifier<LoginPageData> login = ValueNotifier<LoginPageData>(
    LoginPageData.defaults,
  );
  final ValueNotifier<RegisterPageData> register =
      ValueNotifier<RegisterPageData>(RegisterPageData.defaults);

  bool _isLoaded = false;
  Future<void>? _loginInFlight;
  Future<void>? _registerInFlight;
  DateTime? _loginFetchedAt;
  DateTime? _registerFetchedAt;

  /// Loads the cached copies from disk. Called once at startup, before the
  /// first frame, so the login screen never flashes the defaults over an
  /// admin's edit.
  Future<void> init() async {
    if (_isLoaded) return;
    _isLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginRaw = prefs.getString(_prefsLoginKey);
      if (loginRaw != null && loginRaw.isNotEmpty) {
        login.value = LoginPageData.fromJson(jsonDecode(loginRaw));
      }
      final registerRaw = prefs.getString(_prefsRegisterKey);
      if (registerRaw != null && registerRaw.isNotEmpty) {
        register.value = RegisterPageData.fromJson(jsonDecode(registerRaw));
      }
    } catch (e) {
      debugPrint('AuthScreenContentService: cache read failed -> $e');
    }
    _warmLogo(login.value.logoUrl);
    _warmLogo(register.value.logoUrl);
  }

  /// Fetches both screens in parallel. Never awaited on a critical path.
  Future<void> refreshAll() {
    return Future.wait([refreshLogin(), refreshRegister()]);
  }

  Future<void> refreshLogin() {
    return _loginInFlight ??= _fetchLogin().whenComplete(
      () => _loginInFlight = null,
    );
  }

  Future<void> refreshRegister() {
    return _registerInFlight ??= _fetchRegister().whenComplete(
      () => _registerInFlight = null,
    );
  }

  /// Called when a screen opens. Only skips the call when the copy was fetched
  /// moments ago (e.g. the launch fetch just before the first screen), so an
  /// admin's edit shows up the next time the screen is opened.
  void refreshLoginIfStale() {
    if (_isFresh(_loginFetchedAt)) return;
    unawaited(refreshLogin());
  }

  void refreshRegisterIfStale() {
    if (_isFresh(_registerFetchedAt)) return;
    unawaited(refreshRegister());
  }

  bool _isFresh(DateTime? fetchedAt) {
    return fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _minRefetchGap;
  }

  Future<void> _fetchLogin() async {
    final data = await _fetch(ApiService.APP_SCREEN_LOGIN);
    if (data == null) return;
    _loginFetchedAt = DateTime.now();

    final next = LoginPageData.fromJson(data);
    final encoded = jsonEncode(next.toJson());
    // Redraw only when something actually changed.
    if (encoded == jsonEncode(login.value.toJson())) return;

    _warmLogo(next.logoUrl);
    login.value = next;
    await _save(_prefsLoginKey, encoded);
  }

  Future<void> _fetchRegister() async {
    final data = await _fetch(ApiService.APP_SCREEN_REGISTER);
    if (data == null) return;
    _registerFetchedAt = DateTime.now();

    final next = RegisterPageData.fromJson(data);
    final encoded = jsonEncode(next.toJson());
    if (encoded == jsonEncode(register.value.toJson())) return;

    _warmLogo(next.logoUrl);
    register.value = next;
    await _save(_prefsRegisterKey, encoded);
  }

  /// Returns `data` of a successful answer, or `null` to keep the current copy.
  Future<Map<String, dynamic>?> _fetch(String endpoint) async {
    try {
      final response = await ApiService.instance.get<dynamic>(
        endpoint: endpoint,
        includeAuth: false,
        showLoader: false,
        fromJson: (json) => json,
      );
      if (!response.success || response.data is! Map) {
        debugPrint(
          'AuthScreenContentService: keeping cached $endpoint '
          '(${response.statusCode} ${response.message})',
        );
        return null;
      }
      final data = (response.data as Map)['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (e) {
      debugPrint('AuthScreenContentService: fetch $endpoint failed -> $e');
      return null;
    }
  }

  Future<void> _save(String key, String encoded) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, encoded);
    } catch (e) {
      debugPrint('AuthScreenContentService: cache write failed -> $e');
    }
  }

  /// Pre-loads the admin logo into the image cache so the screen shows it
  /// without a pop-in. Failures are ignored; the widget falls back to the
  /// bundled logo on its own.
  void _warmLogo(String? url) {
    if (url == null) return;
    final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) => stream.removeListener(listener),
      onError: (_, _) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }
}
