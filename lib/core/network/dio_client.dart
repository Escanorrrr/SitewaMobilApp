import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../cache/cache_manager.dart';

@injectable
class DioClient {
  final Dio _dio;

  DioClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.example.com', // TODO: Update with your API URL
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 3),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO: Add token to headers if available
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
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

class _AuthInterceptor extends Interceptor {
  final ICacheManager _cacheManager;

  _AuthInterceptor(this._cacheManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _cacheManager.read<String>(ApiConstants.tokenKey);
    final siteCode = await _cacheManager.read<String>(ApiConstants.siteCodeKey);

    if (token != null) {
      options.headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$token';
    }

    if (siteCode != null) {
      options.headers[ApiConstants.siteCodeHeader] = siteCode;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _cacheManager.read<String>(ApiConstants.refreshTokenKey);
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
            data: {'refreshToken': refreshToken},
          );

          final newToken = response.data['token'] as String;
          await _cacheManager.write(ApiConstants.tokenKey, newToken);

          err.requestOptions.headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$newToken';

          final newResponse = await Dio().fetch(err.requestOptions);
          return handler.resolve(newResponse);
        } catch (_) {
          await _cacheManager.clearAll();
        }
      }
    }
    handler.next(err);
  }
} 