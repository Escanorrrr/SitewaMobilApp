import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/login_request.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';
import '../../data/providers/auth_providers.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> login(LoginRequest request) async {
    state = const AuthState.loading();

    final result = await ref.read(authRepositoryProvider).login(request);

    state = result.fold(
      (failure) => AuthState.error(failure.message),
      (response) => AuthState.authenticated(response),
    );
  }

  Future<void> logout() async {
    state = const AuthState.loading();

    final result = await ref.read(authRepositoryProvider).logout();

    state = result.fold(
      (failure) => AuthState.error(failure.message),
      (_) => const AuthState.unauthenticated(),
    );
  }

  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();

    final result = await ref.read(authRepositoryProvider).getCurrentUser();

    state = result.fold(
      (failure) => const AuthState.unauthenticated(),
      (response) => AuthState.authenticated(response),
    );
  }
}

@riverpod
IAuthRepository authRepository(AuthRepositoryRef ref) =>
    ref.watch(authRepositoryProvider); 