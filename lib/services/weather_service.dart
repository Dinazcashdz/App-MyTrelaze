import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/secrets.dart';

class WeatherService {
  static const String _apiKey = Secrets.openWeatherApiKey;
  static const String _city = 'Trélazé,FR';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _cacheKeyWeather = 'cache_weather';

  /// Returns weather data. When served from cache, contains `'_fromCache': true`.
  static Future<Map<String, dynamic>?> getWeather() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$_city&appid=$_apiKey&units=metric&lang=fr',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Persist to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKeyWeather, response.body);
        return data;
      }
    } catch (_) {}
    // Fallback to cache
    return _loadCachedWeather();
  }

  static Future<Map<String, dynamic>?> _loadCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKeyWeather);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        data['_fromCache'] = true;
        return data;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> getForecast() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?q=$_city&appid=$_apiKey&units=metric&lang=fr&cnt=40',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['list'] as List;

        // Groupe par jour — prend 1 entrée par jour
        final Map<String, Map<String, dynamic>> byDay = {};
        for (final item in list) {
          final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dayKey = '${dt.year}-${dt.month}-${dt.day}';
          if (!byDay.containsKey(dayKey)) {
            byDay[dayKey] = item;
          }
        }
        return byDay.values.take(7).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getHourlyForecast() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?q=$_city&appid=$_apiKey&units=metric&lang=fr&cnt=9',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['list'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static List<Color> getGradientColors(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return const [Color(0xFF1B6CA8), Color(0xFF3D8BC7), Color(0xFF6AB0E0)];
      case 'clouds':
        return const [Color(0xFF3D4F63), Color(0xFF5A6D82), Color(0xFF8095AA)];
      case 'rain':
        return const [Color(0xFF1A2D47), Color(0xFF254566), Color(0xFF2E5B80)];
      case 'drizzle':
        return const [Color(0xFF253E5C), Color(0xFF3A587A), Color(0xFF5077A0)];
      case 'thunderstorm':
        return const [Color(0xFF14141F), Color(0xFF1E1E35), Color(0xFF2A2A50)];
      case 'snow':
        return const [Color(0xFF4A7B9D), Color(0xFF7AABCC), Color(0xFFB0D4EC)];
      case 'mist':
      case 'fog':
      case 'haze':
        return const [Color(0xFF5A6A7A), Color(0xFF7A8A9A), Color(0xFF9AAABB)];
      default:
        return const [Color(0xFF2C5F8A), Color(0xFF4A7DAD), Color(0xFF6E9EC7)];
    }
  }

  static String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':        return '☀️';
      case 'clouds':       return '☁️';
      case 'rain':         return '🌧️';
      case 'drizzle':      return '🌦️';
      case 'thunderstorm': return '⛈️';
      case 'snow':         return '❄️';
      case 'mist':
      case 'fog':          return '🌫️';
      default:             return '🌤️';
    }
  }

  static String getDayName(DateTime dt) {
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final now = DateTime.now();
    if (dt.day == now.day) return 'Aujourd\'hui';
    if (dt.day == now.add(const Duration(days: 1)).day) return 'Demain';
    return jours[dt.weekday - 1];
  }
}