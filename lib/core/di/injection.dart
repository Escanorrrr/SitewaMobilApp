import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../storage/cache_manager.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<ICacheManager>(CacheManager(prefs));
  getIt.registerSingleton<DioClient>(DioClient());
  getIt.registerSingleton<IAuthRepository>(AuthRepositoryImpl(getIt(), getIt()));
}

@module
abstract class RegisterModule {} 