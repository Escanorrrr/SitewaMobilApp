import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
IAuthRepository authRepository(AuthRepositoryRef ref) {
  return getIt<IAuthRepository>();
} 