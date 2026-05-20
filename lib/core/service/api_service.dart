import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:edupath_learning/core/service/session_manager.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:flutter/foundation.dart';

import '../utils/loading_dialog.dart';

class ApiService extends GetxService {
  static ApiService get instance => Get.find<ApiService>();

  late Dio _dio;

  ///BASE URL
  static String baseUrl = 'https://api.example.app/api/';

  ///End points
  static const String LOGIN = 'auth/login';
  static const String FORGOT_PASSWORD = "/auth/forgot-password";
  static const String LOGIN_GOOGLE = 'auth/google-login';

  @override
  void onInit() {
    super.onInit();

    _initializeDio();
  }

  void _initializeDio() async{



    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authorization token if available
          final token = SessionManager.instance.userToken;
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            print('REQUEST[${options.method}] => PATH: ${options.path}');
            print('Headers: ${options.headers}');
            print('Data: ${options.data}');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          print('error');
          print(error);
          if (kDebugMode) {
            print('ERROR[${error.response?.statusCode}] => DATA: ${error.response?.data}');
            print(error.response?.data['errorCode']);
          }

          try{
            var errr = error.response?.data;
            /* if(errr['errorCode'] == 'InvalidToken'){
              _handleUnauthorized();
              Get.snackbar('Invalid Token', 'Please Login again to access the app.');
            }*/
          }catch(e){

          }

          // Handle token expiration
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          }

          if (error.response?.statusCode == 500) {
            _handleUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  void _handleUnauthorized() async {
    await SessionManager.instance.logout();
    Get.offAllNamed('/login'); // Navigate to login page
  }

  // Generic API call method
  Future<ApiResponse<T>> _apiCall<T>({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool showLoader = true,
    T Function(dynamic)? fromJson,
  }) async {
    print(endpoint);
    try {
      if (showLoader) {
        //LoadingDialog.show();
      }
      Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dio.get(endpoint, queryParameters: queryParameters);
          print('GET API SERVICE RES $endpoint');
          print('$response');
          break;
        case 'POST':
          response = await _dio.post(endpoint, data: data, queryParameters: queryParameters);
          print('POST API SERVICE RES $endpoint');
          print('$response');
          break;
        case 'PUT':
          response = await _dio.put(endpoint, data: data, queryParameters: queryParameters);
          break;
        case 'DELETE':
          response = await _dio.delete(endpoint, queryParameters: queryParameters);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (showLoader) {
        LoadingDialog.hide();
      }
      print('response.statusCode');
      print(response.data);
      print(response.statusCode);

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T? responseData;
        if (fromJson != null && response.data != null) {

          responseData = fromJson(response.data);
        } else {
          responseData = response.data as T?;
        }

        return ApiResponse<T>(success: true, data: responseData, message: 'Success', statusCode: response.statusCode!);
      } else {

        return ApiResponse<T>(success: false, message: response.data['message'] ?? 'Unknown error occurred', statusCode: response.statusCode!);
      }
    } on DioException catch (e,stack) {
      if (showLoader) {
        LoadingDialog.hide();
      }
      print('=========== DioException ===========');
      print(stack);
      return ApiResponse<T>(success: false, message: _handleDioError(e), statusCode: e.response?.statusCode ?? 0);
    } catch (e, stack) {
      print('=========== catch ===========');
      if (showLoader) {
        LoadingDialog.hide();
      }
      print(stack);
      //e.printError();
      return ApiResponse<T>(success: false, message: 'Unexpected error occurred: ${e.toString()}', statusCode: 0);
    }
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        if (error.response?.data != null && error.response?.data is Map) {
          return error.response?.data['message'] ?? 'Server error occurred';
        }
        return 'Server error occurred';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.unknown:
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred';
    }
  }

  ///GET Request
  Future<ApiResponse<T>> get<T>({required String endpoint,
    Map<String, dynamic>? queryParameters,
    bool showLoader = true,
    T Function(dynamic)? fromJson}) async {
    return _apiCall<T>(method: 'GET', endpoint: endpoint, queryParameters: queryParameters, showLoader: showLoader, fromJson: fromJson);
  }

  ///POST Request
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool showLoader = true,
    T Function(dynamic)? fromJson,
  }) async {
    return _apiCall<T>(method: 'POST', endpoint: endpoint, data: data, queryParameters: queryParameters, showLoader: showLoader, fromJson: fromJson);
  }

  ///PUT Request
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool showLoader = true,
    T Function(dynamic)? fromJson,
  }) async {
    return _apiCall<T>(method: 'PUT', endpoint: endpoint, data: data, queryParameters: queryParameters, showLoader: showLoader, fromJson: fromJson);
  }

  ///DELETE Request
  Future<ApiResponse<T>> delete<T>({required String endpoint, Map<String, dynamic>? queryParameters, bool showLoader = true, T Function(dynamic)? fromJson}) async {
    return _apiCall<T>(method: 'DELETE', endpoint: endpoint, queryParameters: queryParameters, showLoader: showLoader, fromJson: fromJson);
  }
}


class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final int statusCode;

  ApiResponse({required this.success, this.data, required this.message, required this.statusCode});

  @override
  String toString() {
    return 'ApiResponse{success: $success, data: $data, message: $message, statusCode: $statusCode}';
  }
}
