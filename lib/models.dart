class City {
  final String name;
  final String country;
  final String region;
  final double latitude;
  final double longitude;

  const City({
    required this.name,
    required this.country,
    required this.region,
    required this.latitude,
    required this.longitude,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        name: json['name'] as String? ?? '',
        country: json['country'] as String? ?? '',
        region: json['admin1'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'admin1': region,
        'latitude': latitude,
        'longitude': longitude,
      };

  String get label =>
      [name, region, country].where((s) => s.isNotEmpty).join(', ');
}

class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double minTemp;
  final double maxTemp;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.minTemp,
    required this.maxTemp,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: DateTime.parse(json['date'] as String),
        weatherCode: json['code'] as int,
        minTemp: (json['min'] as num).toDouble(),
        maxTemp: (json['max'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'code': weatherCode,
        'min': minTemp,
        'max': maxTemp,
      };
}

class WeatherData {
  final City city;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final List<DailyForecast> forecast;
  final DateTime fetchedAt;

  const WeatherData({
    required this.city,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.forecast,
    required this.fetchedAt,
  });

  /// Builds from the Open-Meteo forecast response.
  factory WeatherData.fromApi(City city, Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    final dates = daily['time'] as List;
    final codes = daily['weather_code'] as List;
    final maxes = daily['temperature_2m_max'] as List;
    final mins = daily['temperature_2m_min'] as List;

    return WeatherData(
      city: city,
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).round(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      forecast: List.generate(
        dates.length,
        (i) => DailyForecast(
          date: DateTime.parse(dates[i] as String),
          weatherCode: (codes[i] as num).toInt(),
          minTemp: (mins[i] as num).toDouble(),
          maxTemp: (maxes[i] as num).toDouble(),
        ),
      ),
      fetchedAt: DateTime.now(),
    );
  }

  /// Builds from our own saved cache.
  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        city: City.fromJson(json['city'] as Map<String, dynamic>),
        temperature: (json['temperature'] as num).toDouble(),
        humidity: json['humidity'] as int,
        windSpeed: (json['windSpeed'] as num).toDouble(),
        weatherCode: json['weatherCode'] as int,
        forecast: (json['forecast'] as List)
            .map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
            .toList(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'city': city.toJson(),
        'temperature': temperature,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'weatherCode': weatherCode,
        'forecast': forecast.map((e) => e.toJson()).toList(),
        'fetchedAt': fetchedAt.toIso8601String(),
      };
}