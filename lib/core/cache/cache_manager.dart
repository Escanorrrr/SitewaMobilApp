import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

abstract class ICacheManager {
  Future<void> init();
  Future<void> write<T>(String key, T value);
  Future<T?> read<T>(String key);
  Future<void> delete(String key);
  Future<void> clearAll();
}

@Singleton(as: ICacheManager)
class CacheManager implements ICacheManager {
  late Box<dynamic> _box;
  
  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('sitewa_cache');
  }
  
  @override
  Future<void> write<T>(String key, T value) async {
    await _box.put(key, value);
  }
  
  @override
  Future<T?> read<T>(String key) async {
    return _box.get(key) as T?;
  }
  
  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }
  
  @override
  Future<void> clearAll() async {
    await _box.clear();
  }
} 