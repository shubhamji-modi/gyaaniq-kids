import 'package:dio/dio.dart';
import 'package:edupath_learning/core/service/session_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:flutter/foundation.dart';

import '../values/constants.dart';
import '../utils/loading_dialog.dart';

class ApiService extends GetxService {
  static ApiService get instance => Get.find<ApiService>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Dio _dio;

  ///BASE URL
  static String baseUrl =
      'https://c78a-2405-201-301c-203c-250a-998-3f5-2a68.ngrok-free.app/api/v1/';

  ///End points
  static const String REGISTER = 'auth/register';
  static const String LOGIN = 'auth/login';
  static const String LOGOUT = 'auth/logout';
  static const String DELETE_ACCOUNT = 'user/account';
  static const String GET_PROFILE = 'user/profile';
  static const String EDIT_PROFILE = 'user/profile/setup';
  static const String STUDENT_PROFILE_SETUP = 'user/profile/setup';
  static const String GET_USER_SUBJECT = 'user/subjects';
  static const String GET_USER_LESSON = 'user/lessons/by-class-subject';
  static const String FETCH_EBOOKS_BY_CLASS_SUBJECT =
      'user/ebooks/by-class-subject';
  static const String FETCH_NOTES_BY_LESSON = 'user/notes/by-lesson';
  static const String FETCH_QUIZZES = 'user/quizzes/by-lesson';
  static const String FETCH_SINGLE_QUIZZES = 'user/quizzes/:id';
  static const String SUBMIT_PRACTICE_QUIZZES = 'user/quizzes/:id/attempt';
  static const String GET_SUBMIT_RESULT = 'user/progress/quizzes/attempts';
  static const String DASHBOARD_PROGRESS_SUMMARY = 'user/progress/summary';
  static const String MARK_A_LESSON = 'user/progress/lessons/:id/complete';
  static const String MARK_START_LESSON = 'user/progress/lessons/:id/start';
  static const String GET_PROGRESS_ONE_LESSON = 'user/progress/lessons/:id';
  static const String DAILY_QUIZZS = 'user/daily-quiz/today';
  static const String DAILY_QUIZZS_ATTEMPT = 'user/daily-quiz/today/attempt';
  static const String DAILY_QUIZZS_HISTORY = 'user/daily-quiz/my-attempts';
  static const String USER_MOCK_TEST = 'user/mock-tests';
  static const String FETCH_MOCK_TEST = 'user/mock-tests/:id';
  static const String SUBMIT_MOCK_TEST = 'user/mock-tests/:id/attempt';
  static const String MOCK_TEST_HISTORY = 'user/mock-tests/my-attempts';
  static const String USER_LEADERBOARD = 'user/leaderboard';
  static const String PRACTICE_FEEDBACK = 'user/progress/quizzes/attempts/:id';
  static const String DAILY_QUIZ_FEEDBACK = 'user/daily-quiz/my-attempts/:id';
  static const String MOCK_FEEDBACK = 'user/mock-tests/my-attempts/:id';
  static const String LIVE_CLASS = 'user/live-classes';
  static const String HOMEWORK = 'user/homework';
  static const String HOMEWORK_DETAIL = 'user/homework/:id';
  static const String HOMEWORK_SUBMIT = 'user/homework/:id/submit';
  static const String HOMEWORK_UPLOAD_ATTACHMENT =
      'user/homework/upload-attachment';
  static const String HOMEWORK_MY_SUBMISSIONS = 'user/homework/my-submissions';

  @override
  void onInit() {
    super.onInit();

    _initializeDio();
  }

  void _initializeDio() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
            print(
              'ERROR[${error.response?.statusCode}] => DATA: ${error.response?.data}',
            );
            print(error.response?.data['errorCode']);
          }

          try {
            var errr = error.response?.data;
            /* if(errr['errorCode'] == 'InvalidToken'){
              _handleUnauthorized();
              Get.snackbar('Invalid Token', 'Please Login again to access the app.');
            }*/
          } catch (e) {}

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
    await _storage.delete(key: StorageKeys.authToken);
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
          response = await _dio.post(
            endpoint,
            data: data,
            queryParameters: queryParameters,
          );
          print('POST API SERVICE RES $endpoint');
          print('$response');
          break;
        case 'PUT':
          response = await _dio.put(
            endpoint,
            data: data,
            queryParameters: queryParameters,
          );
          break;
        case 'DELETE':
          response = await _dio.delete(
            endpoint,
            queryParameters: queryParameters,
          );
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

        return ApiResponse<T>(
          success: true,
          data: responseData,
          message: 'Success',
          statusCode: response.statusCode!,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          message: response.data['message'] ?? 'Unknown error occurred',
          statusCode: response.statusCode!,
        );
      }
    } on DioException catch (e, stack) {
      if (showLoader) {
        LoadingDialog.hide();
      }
      print('=========== DioException ===========');
      print(stack);
      return ApiResponse<T>(
        success: false,
        message: _handleDioError(e),
        statusCode: e.response?.statusCode ?? 0,
      );
    } catch (e, stack) {
      print('=========== catch ===========');
      if (showLoader) {
        LoadingDialog.hide();
      }
      print(stack);
      //e.printError();
      return ApiResponse<T>(
        success: false,
        message: 'Unexpected error occurred: ${e.toString()}',
        statusCode: 0,
      );
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
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    bool showLoader = true,
    T Function(dynamic)? fromJson,
  }) async {
    return _apiCall<T>(
      method: 'GET',
      endpoint: endpoint,
      queryParameters: queryParameters,
      showLoader: showLoader,
      fromJson: fromJson,
    );
  }

  ///POST Request
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool showLoader = true,
    T Function(dynamic)? fromJson,
  }) async {
    return _apiCall<T>(
      method: 'POST',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      showLoader: showLoader,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> uploadFile<T>({
    required String endpoint,
    required String filePath,
    String fieldName = 'file',
    bool showLoader = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (showLoader) {
        //LoadingDialog.show();
      }

      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (showLoader) {
        LoadingDialog.hide();
      }

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T? responseData;
        if (fromJson != null && response.data != null) {
          responseData = fromJson(response.data);
        } else {
          responseData = response.data as T?;
        }

        return ApiResponse<T>(
          success: true,
          data: responseData,
          message: 'Success',
          statusCode: response.statusCode!,
        );
      }

      return ApiResponse<T>(
        success: false,
        message: response.data['message'] ?? 'Unknown error occurred',
        statusCode: response.statusCode!,
      );
    } on DioException catch (e) {
      if (showLoader) {
        LoadingDialog.hide();
      }
      return ApiResponse<T>(
        success: false,
        message: _handleDioError(e),
        statusCode: e.response?.statusCode ?? 0,
      );
    } catch (e) {
      if (showLoader) {
        LoadingDialog.hide();
      }
      return ApiResponse<T>(
        success: false,
        message: 'Unexpected error occurred: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  ///PUT Request
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool showLoader = true,
    T Function(dynamic)? fromJson,
  }) async {
    return _apiCall<T>(
      method: 'PUT',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      showLoader: showLoader,
      fromJson: fromJson,
    );
  }

  ///DELETE Request
  Future<ApiResponse<T>> delete<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    bool showLoader = true,
    T Function(dynamic)? fromJson,
  }) async {
    return _apiCall<T>(
      method: 'DELETE',
      endpoint: endpoint,
      queryParameters: queryParameters,
      showLoader: showLoader,
      fromJson: fromJson,
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() {
    return 'ApiResponse{success: $success, data: $data, message: $message, statusCode: $statusCode}';
  }
}
