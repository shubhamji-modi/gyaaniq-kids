import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';
import '../values/constants.dart';
import 'api_service.dart';
import 'session_manager.dart';

class AuthService extends GetxService {
  static AuthService get instance => Get.find<AuthService>();

  final ApiService _apiService = ApiService.instance;
  final SessionManager _sessionManager = SessionManager.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) {
    return _authenticate(
      endpoint: ApiService.LOGIN,
      payload: {'email': email.trim(), 'password': password},
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _authenticate(
      endpoint: ApiService.REGISTER,
      payload: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> _authenticate({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _apiService.post<dynamic>(
      endpoint: endpoint,
      data: payload,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final token = data?['token']?.toString() ?? '';
    final userId = data?['_id']?.toString() ?? '';
    final name = data?['name']?.toString() ?? '';
    final email = data?['email']?.toString() ?? '';

    if (token.isEmpty || userId.isEmpty) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: body['message']?.toString() ?? 'Authentication failed',
        statusCode: response.statusCode,
      );
    }

    await _storage.write(key: StorageKeys.authToken, value: token);
    await _sessionManager.login(
      token: token,
      userId: userId,
      userData: name,
      email: email,
    );

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('user_name', name);
    await preferences.setString('user_email', email);

    return ApiResponse<Map<String, dynamic>>(
      success: true,
      data: body,
      message: body['message']?.toString() ?? 'Success',
      statusCode: response.statusCode,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _sessionManager.logout();
    Get.offAllNamed(AppRoutes.login);
  }
}
