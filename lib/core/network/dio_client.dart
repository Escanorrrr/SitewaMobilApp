import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';
import '../cache/cache_manager.dart';

@singleton
class DioClient {
  final ICacheManager _cacheManager;
  late final Dio _dio;

  DioClient(this._cacheManager) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
      ),
    )..interceptors.addAll([
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
        ),
        _AuthInterceptor(_cacheManager),
      ]);
  }

  Dio get dio => _dio;
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