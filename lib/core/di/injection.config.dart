// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:sitewa_app/core/cache/cache_manager.dart' as _i145;
import 'package:sitewa_app/core/di/injection.dart' as _i555;
import 'package:sitewa_app/core/network/dio_client.dart' as _i269;
import 'package:sitewa_app/core/storage/cache_manager.dart' as _i198;
import 'package:sitewa_app/features/auth/data/repositories/auth_repository_impl.dart'
    as _i723;
import 'package:sitewa_app/features/auth/domain/repositories/auth_repository.dart'
    as _i622;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i145.ICacheManager>(() => _i145.CacheManager());
    gh.singleton<_i198.ICacheManager>(
        () => _i198.CacheManager(gh<_i460.SharedPreferences>()));
    gh.singleton<_i269.DioClient>(
        () => _i269.DioClient(gh<_i198.ICacheManager>()));
    gh.singleton<_i622.IAuthRepository>(() => _i723.AuthRepositoryImpl(
          gh<_i269.DioClient>(),
          gh<_i198.ICacheManager>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i555.RegisterModule {}
