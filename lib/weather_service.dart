import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'models.dart';

class WeatherException implements Exception {
  final String message;
  final bool isNetwork;
  const WeatherException(this.message, {this.isNetwork = false});
}

class WeatherService {
  final http.Client _client = http.Client();

  Future<List<City>> searchCity(String name) async {
    final uri = Uri.parse(ApiConstants.geocodingUrl).replace(
      queryParameters: {'name': name, 'count': ApiConstants.cityResultCount},
    );
    final json = await _get(uri);
    final results = json['results'] as List?;
    if (results == null || results.isEmpty) {
      throw const WeatherException(
          'City not found. Check the spelling and try again.');
    }
    try {
      return results
          .map((e) => City.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const WeatherException('Unexpected data received. Try again.');
    }
  }

  Future<WeatherData> fetchWeather(City city) async {
    final uri = Uri.parse(ApiConstants.forecastUrl).replace(queryParameters: {
      'latitude': city.latitude.toString(),
      'longitude': city.longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'forecast_days': ApiConstants.forecastDays,
      'timezone': 'auto',
    });
    final json = await _get(uri);
    try {
      return WeatherData.fromApi(city, json);
    } catch (_) {
      throw const WeatherException('Unexpected data received. Try again.');
    }
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(ApiConstants.timeout);
      if (response.statusCode != 200) {
        throw WeatherException(
            'Server error (${response.statusCode}). Please try again later.');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on WeatherException {
      rethrow;
    } on TimeoutException {
      throw const WeatherException(
          'The request timed out. Check your connection and try again.',
          isNetwork: true);
    } on http.ClientException {
      throw const WeatherException(
          'No internet connection. Please check your network.',
          isNetwork: true);
    } on FormatException {
      throw const WeatherException('Unexpected data received. Try again.');
    } catch (_) {
      throw const WeatherException('Something went wrong. Please try again.');
    }
  }
}