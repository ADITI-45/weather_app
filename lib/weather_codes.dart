class WeatherInfo {
  final String description;
  final String icon;
  const WeatherInfo(this.description, this.icon);
}

WeatherInfo weatherInfoFor(int code) {
  switch (code) {
    case 0:
      return const WeatherInfo('Clear sky', '☀️');
    case 1:
      return const WeatherInfo('Mainly clear', '🌤️');
    case 2:
      return const WeatherInfo('Partly cloudy', '⛅');
    case 3:
      return const WeatherInfo('Overcast', '☁️');
    case 45:
    case 48:
      return const WeatherInfo('Fog', '🌫️');
    case 51:
      return const WeatherInfo('Light drizzle', '🌦️');
    case 53:
      return const WeatherInfo('Moderate drizzle', '🌦️');
    case 55:
      return const WeatherInfo('Dense drizzle', '🌦️');
    case 61:
      return const WeatherInfo('Slight rain', '🌧️');
    case 63:
      return const WeatherInfo('Moderate rain', '🌧️');
    case 65:
      return const WeatherInfo('Heavy rain', '🌧️');
    case 71:
      return const WeatherInfo('Slight snow', '🌨️');
    case 73:
      return const WeatherInfo('Moderate snow', '🌨️');
    case 75:
      return const WeatherInfo('Heavy snow', '❄️');
    case 80:
    case 81:
    case 82:
      return const WeatherInfo('Rain showers', '🌦️');
    case 95:
      return const WeatherInfo('Thunderstorm', '⛈️');
    case 96:
    case 99:
      return const WeatherInfo('Thunderstorm with hail', '⛈️');
    default:
      return const WeatherInfo('Unknown', '🌡️');
  }
}