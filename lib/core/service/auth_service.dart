import 'dart:convert';

import 'package:get/get.dart';
import '../../modules/auth/modules/login_request.dart';
import '../../modules/auth/modules/login_response.dart';
import 'api_service.dart';
import 'session_manager.dart';

class AuthService extends GetxService {
  static AuthService get instance => Get.find<AuthService>();

  final ApiService _apiService = ApiService.instance;
  final SessionManager _sessionManager = SessionManager.instance;



  // Login method
  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginRequest = LoginRequest(
        email: email,
        password: password,
      );

      final response = await _apiService.post<LoginResponse>(
        endpoint: ApiService.LOGIN,
        data: loginRequest.toJson(),
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Check if the API response indicates success
        if (response.data!.status == 'success') {
          // Save session data
          await _sessionManager.login(
            token: response.data!.token,
            userId: response.data!.user.id,
            userData: response.data!.user.name,
            email: response.data!.user.email,
            profilePic: response.data!.user.profilePicture,
          );

          return ApiResponse<LoginResponse>(
            success: true,
            data: response.data,
            message: response.data!.message,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse<LoginResponse>(
            success: false,
            message: response.data!.message,
            statusCode: response.statusCode,
          );
        }
      }

      return response;
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        message: 'Login failed: ${e.toString()}',
        statusCode: 0,
      );
    }
  }


  // Login method
  Future<ApiResponse<LoginResponse>> loginGoogle({
    required String email,
    required String name,
  }) async {
    try {
      final loginRequest = Map<String, dynamic>();
      loginRequest['email'] =email;
      loginRequest['name'] =name;

      final response = await _apiService.post<LoginResponse>(
        endpoint: ApiService.LOGIN_GOOGLE,
        data: loginRequest,
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Check if the API response indicates success
        if (response.data!.status == 'success') {
          // Save session data
          await _sessionManager.login(
            token: response.data!.token,
            userId: response.data!.user.id,
            userData: response.data!.user.name,
            email: response.data!.user.email,
          );

          return ApiResponse<LoginResponse>(
            success: true,
            data: response.data,
            message: response.data!.message,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse<LoginResponse>(
            success: false,
            message: response.data!.message,
            statusCode: response.statusCode,
          );
        }
      }

      return response;
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        message: 'Login failed: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // Forgot method
  Future<ApiResponse<dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _apiService.post<dynamic>(
        endpoint: ApiService.FORGOT_PASSWORD,
        data: {
          "email": email,
        },
        fromJson: (json) => json,
      );

      if (response.success) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Reset link sent successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
        statusCode: 0,
      );
    }
  }


  // Logout method
  Future<void> logout() async {
    await _sessionManager.logout();
    Get.offAllNamed('/login');
  }

  // Check if user is authenticated
  bool get isAuthenticated => _sessionManager.isLoggedIn;

  // Get current user token
  String get currentToken => _sessionManager.userToken;

  // Get current user ID
  String get currentUserId => _sessionManager.userId;
}