import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../cache/cache_manager.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Register dependencies
  getIt.registerSingleton<ICacheManager>(CacheManager());
  getIt.registerSingleton<DioClient>(DioClient(getIt()));
  getIt.registerSingleton<IAuthRepository>(AuthRepositoryImpl(getIt(), getIt()));

  // Initialize cache
  await getIt<ICacheManager>().init();
}

@module
abstract class RegisterModule {} 