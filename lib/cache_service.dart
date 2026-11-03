import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class CacheService {
  static const _key = 'last_weather';

  Future<void> save(WeatherData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  Future<WeatherData?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return WeatherData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupted cache should never crash the app
    }
  }
}