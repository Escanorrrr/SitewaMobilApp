import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ICacheManager {
  Future<void> write<T>(String key, T value);
  Future<T?> read<T>(String key);
  Future<void> delete(String key);
  Future<void> clearAll();
}

@Injectable(as: ICacheManager)
class CacheManager implements ICacheManager {
  final SharedPreferences _prefs;

  CacheManager(this._prefs);

  @override
  Future<void> write<T>(String key, T value) async {
    if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await _prefs.setStringList(key, value);
    } else {
      final jsonStr = jsonEncode(value);
      await _prefs.setString(key, jsonStr);
    }
  }

  @override
  Future<T?> read<T>(String key) async {
    final value = _prefs.get(key);
    if (value == null) return null;

    if (T == String) {
      return value as T;
    } else if (T == bool) {
      return value as T;
    } else if (T == int) {
      return value as T;
    } else if (T == double) {
      return value as T;
    } else if (T == List<String>) {
      return value as T;
    } else {
      final jsonStr = value as String;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map as T;
    }
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.clear();
  }
} 