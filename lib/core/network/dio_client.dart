import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../constants/api_constants.dart';
import '../error/error_handler.dart';
import '../storage/cache_manager.dart';

@singleton
class DioClient {
  final Dio _dio;
  final ICacheManager _cacheManager;

  DioClient(this._cacheManager)
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 3),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _cacheManager.read<String>(ApiConstants.tokenKey);
          if (token != null) {
            options.headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshToken = await _cacheManager.read<String>(ApiConstants.refreshTokenKey);
            if (refreshToken != null) {
              try {
                final response = await Dio().post(
                  '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
                  data: {'refreshToken': refreshToken},
                );

                final newToken = response.data['token'] as String;
                await _cacheManager.write(ApiConstants.tokenKey, newToken);

                error.requestOptions.headers[ApiConstants.authorizationHeader] =
                    '${ApiConstants.bearerPrefix}$newToken';

                return handler.resolve(await _dio.fetch(error.requestOptions));
              } catch (e) {
                await _cacheManager.clearAll();
              }
            }
          }

          final errorMessage = ErrorHandler.handleError(error);
          handler.next(
            DioException(
              requestOptions: error.requestOptions,
              error: errorMessage,
              type: error.type,
              response: error.response,
            ),
          );
        },
      ),
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
} 