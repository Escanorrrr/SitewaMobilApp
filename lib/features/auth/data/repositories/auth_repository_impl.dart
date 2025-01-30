import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/login_request.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/repositories/auth_repository.dart';

@Injectable(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final DioClient _dioClient;
  final ICacheManager _cacheManager;

  AuthRepositoryImpl(this._dioClient, this._cacheManager);

  @override
  Future<Either<Failure, LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      final loginResponse = LoginResponse.fromJson(response.data);

      // Token'ları cache'e kaydet
      await _cacheManager.write(ApiConstants.tokenKey, loginResponse.token);
      await _cacheManager.write(ApiConstants.refreshTokenKey, loginResponse.refreshToken);
      await _cacheManager.write(ApiConstants.siteCodeKey, request.siteCode);

      return Right(loginResponse);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data['message'] ?? ApiConstants.serverError,
        code: e.response?.statusCode.toString(),
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: ApiConstants.unknownError,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _cacheManager.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: ApiConstants.unknownError,
      ));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final newToken = response.data['token'] as String;
      await _cacheManager.write(ApiConstants.tokenKey, newToken);

      return Right(newToken);
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data['message'] ?? ApiConstants.serverError,
        code: e.response?.statusCode.toString(),
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: ApiConstants.unknownError,
      ));
    }
  }

  @override
  Future<Either<Failure, LoginResponse>> getCurrentUser() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.userProfile);
      return Right(LoginResponse.fromJson(response.data));
    } on DioException catch (e) {
      return Left(ServerFailure(
        message: e.response?.data['message'] ?? ApiConstants.serverError,
        code: e.response?.statusCode.toString(),
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: ApiConstants.unknownError,
      ));
    }
  }
} 