import 'package:dio/dio.dart';
import '../../../core/errors/exceptions.dart';

/// Base API client with common configuration
class APIClientBase {
  final Dio _dio;
  final String baseUrl;
  final Map<String, String>? defaultHeaders;

  APIClientBase({
    required this.baseUrl,
    this.defaultHeaders,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: defaultHeaders,
    );

    // Add interceptors
    _dio.interceptors.add(_RequestInterceptor());
    _dio.interceptors.add(_ResponseInterceptor());
    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  Dio get dio => _dio;

  /// Make GET request with error handling
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Make POST request with error handling
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ServerException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerException('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return ServerException(
          'Server error: $statusCode',
          null,
          statusCode,
        );
      case DioExceptionType.cancel:
        return ServerException('Request cancelled');
      case DioExceptionType.connectionError:
        return ServerException('No internet connection');
      default:
        return ServerException('Unknown error: ${error.message}');
    }
  }
}

/// Request interceptor for logging and adding headers
class _RequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Log request in debug mode (use logger in production)
    // print('REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }
}

/// Response interceptor for logging
class _ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log response in debug mode (use logger in production)
    // print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error in debug mode (use logger in production)
    // print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}

/// Retry interceptor with exponential backoff
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);

  _RetryInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return super.onError(err, handler);
    }

    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (retryCount >= maxRetries) {
      return super.onError(err, handler);
    }

    // Calculate delay with exponential backoff
    final delay = initialDelay * (1 << retryCount);
    await Future.delayed(delay);

    // Retry request
    err.requestOptions.extra['retryCount'] = retryCount + 1;

    try {
      final response = await _dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return super.onError(e, handler);
    }
  }

  bool _shouldRetry(DioException err) {
    // Retry on timeout or 5xx errors
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}
