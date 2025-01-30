import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../domain/entities/login_request.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

@Injectable(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  final DioClient _dioClient;
  final ICacheManager _cacheManager;

  AuthRepositoryImpl(this._dioClient, this._cacheManager);

  @override
  Future<Either<Failure, User>> login(LoginRequest request) async {
    try {
      final response = await _dioClient.post(
        '/auth/login',
        data: {
          'email': request.email,
          'password': request.password,
        },
      );

      if (response.statusCode == 200) {
        final userModel = UserModel.fromJson(response.data);
        await _cacheManager.write('token', userModel.token);
        await _cacheManager.write('user', userModel);
        return Right(userModel.toEntity());
      }

      return const Left(ServerFailure('Giriş başarısız'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _cacheManager.delete('token');
      await _cacheManager.delete('user');
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userModel = await _cacheManager.read<UserModel>('user');
      if (userModel != null) {
        return Right(userModel.toEntity());
      }
      return const Left(CacheFailure('Kullanıcı bulunamadı'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
} 