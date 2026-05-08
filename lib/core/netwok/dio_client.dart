import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../utils/constants.dart';

class DioClient {
  static Dio get tmdb => _build(
        baseUrl: 'https://api.themoviedb.org/3',
        queryParams: {'api_key': AppConstants.tmdbApiKey},
      );

  static Dio get reqres => _build(
        baseUrl: 'https://reqres.in/api',
        headers: {'x-api-key': AppConstants.reqresApiKey},
      );

  static Dio _build({
    required String baseUrl,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      queryParameters: queryParams,
      headers: headers,
    ));

    // Exponential backoff — 3 retries
    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: debugPrint,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 3),
        Duration(seconds: 6),
      ],
    ));

    // Reject request immediately if offline
    dio.interceptors.add(_ConnectivityInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: false,
      ));
    }

    return dio;
  }
}

class _ConnectivityInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'No internet connection',
        ),
        true,
      );
    }
    handler.next(options);
  }
}
