import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager extends GetxService {
  static SessionManager get instance => Get.find<SessionManager>();

  SharedPreferences? _prefs;

  // Keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserToken = 'user_token';
  static const String _keyUserData = 'user_data';
  static const String _keyUserEmail = 'user_email';
  static const String _keyProfilePic = 'profile_pic';
  static const String _keyLanguage = 'language';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyIntroSliderAvatar = 'intro_slider';
  static const String _keyIntroSliderProduct = 'intro_slider_product';

  // Reactive variables
  final RxBool _isLoggedIn = false.obs;
  final RxBool isFirstTime = true.obs;
  final RxString _userToken = ''.obs;
  final RxString _userId = ''.obs;
  final RxString _language = 'en'.obs;
  final RxString _themeMode = 'system'.obs;

  // Getters
  bool get isLoggedIn => _isLoggedIn.value;
  String get userToken => _userToken.value;
  String get userId => _userId.value;
  String get language => _language.value;
  String get themeMode => _themeMode.value;

  // Reactive getters
  RxBool get isLoggedInRx => _isLoggedIn;
  RxString get userTokenRx => _userToken;
  RxString get userIdRx => _userId;
  RxString get languageRx => _language;
  RxString get themeModeRx => _themeMode;

  Future<SessionManager> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSessionData();
    return this;
  }

  Future<bool> hasSeenAvatarIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIntroSliderAvatar) ?? false;
  }

  Future<bool> hasSeenProductIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIntroSliderProduct) ?? false;
  }

  Future<void> setSeenAvatarIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroSliderAvatar, true);
  }

  Future<bool> setSeenProductIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIntroSliderProduct) ?? false;
  }

  Future<void> _loadSessionData() async {
    if (_prefs != null) {
      _isLoggedIn.value = _prefs!.getBool(_keyIsLoggedIn) ?? false;
      _userToken.value = _prefs!.getString(_keyUserToken) ?? '';
      _userId.value = _prefs!.getString(_keyUserId) ?? '';
      _language.value = _prefs!.getString(_keyLanguage) ?? 'en';
      _themeMode.value = _prefs!.getString(_keyThemeMode) ?? 'system';
    }
  }

  // Login
  Future<void> login({
    required String token,
    required String userId,
    String? userData,
    String? email,
    String? profilePic,
  }) async {
    _isLoggedIn.value = true;
    _userToken.value = token;
    _userId.value = userId;

    await _prefs?.setBool(_keyIsLoggedIn, true);
    await _prefs?.setString(_keyUserToken, token);
    await _prefs?.setString(_keyUserId, userId);

    if (userData != null && email !=null ) {
      await _prefs?.setString(_keyUserData, userData);
      await _prefs?.setString(_keyUserEmail, email);
    }

    if(profilePic != null){

      await _prefs?.setString(_keyProfilePic, profilePic);

    }
  }

  // Logout
  Future<void> logout() async {
    _isLoggedIn.value = false;
    _userToken.value = '';
    _userId.value = '';

    await _prefs?.setBool(_keyIsLoggedIn, false);
    await _prefs?.remove(_keyUserToken);
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyUserData);
  }

  // Update token
  Future<void> updateToken(String token) async {
    _userToken.value = token;
    await _prefs?.setString(_keyUserToken, token);
  }

  // Language
  Future<void> setLanguage(String languageCode) async {
    _language.value = languageCode;
    await _prefs?.setString(_keyLanguage, languageCode);
    Get.updateLocale(Locale(languageCode));
  }

  // Theme
  Future<void> setThemeMode(String mode) async {
    _themeMode.value = mode;
    await _prefs?.setString(_keyThemeMode, mode);
  }

  // Get user data
  String? getUserData() {
    return _prefs?.getString(_keyUserData);
  }  // Get user data

  String? getUserEmail() {
    return _prefs?.getString(_keyUserEmail);
  }
  String? getUserProfile() {
    return _prefs?.getString(_keyProfilePic);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
    _isLoggedIn.value = false;
    _userToken.value = '';
    _userId.value = '';
    _language.value = 'en';
    _themeMode.value = 'system';
  }

  // Check if token is valid (you can implement your own logic)
  bool isTokenValid() {
    if (_userToken.value.isEmpty) return false;
    // Add your token validation logic here
    // For example, check expiration date
    return true;
  }
}