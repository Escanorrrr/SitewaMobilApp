import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/login_request.dart';
import '../entities/login_response.dart';

abstract class IAuthRepository {
  Future<Either<Failure, LoginResponse>> login(LoginRequest request);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, String>> refreshToken(String refreshToken);
  Future<Either<Failure, LoginResponse>> getCurrentUser();
} 