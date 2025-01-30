import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/login_request.dart';
import '../entities/user.dart';

abstract class IAuthRepository {
  Future<Either<Failure, User>> login(LoginRequest request);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User>> getCurrentUser();
} 