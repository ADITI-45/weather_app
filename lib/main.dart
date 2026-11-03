import 'package:flutter/material.dart';
import 'cache_service.dart';
import 'models.dart';
import 'weather_codes.dart';
import 'weather_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _controller = TextEditingController();
  final _service = WeatherService();
  final _cache = CacheService();

  WeatherData? _weather;
  bool _loading = false;
  bool _isStale = false;
  String? _error;
  int _requestId = 0; // used to ignore outdated responses

  @override
  void initState() {
    super.initState();
    _restoreFromCache();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restoreFromCache() async {
    final cached = await _cache.load();
    if (cached == null || !mounted) return;
    setState(() {
      _weather = cached;
      _isStale = true;
    });
    await _loadWeather(cached.city);
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final text = _controller.text.trim();
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid city name.')),
      );
      return;
    }

    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cities = await _service.searchCity(text);
      if (id != _requestId || !mounted) return;

      City? city = cities.first;
      if (cities.length > 1) city = await _pickCity(cities);
      if (!mounted || id != _requestId) return;
      if (city == null) {
        setState(() => _loading = false);
        return;
      }
      await _loadWeather(city);
    } on WeatherException catch (e) {
      if (id == _requestId && mounted) _handleError(e);
    }
  }

  Future<void> _loadWeather(City city) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchWeather(city);
      if (id != _requestId || !mounted) return;
      await _cache.save(data);
      setState(() {
        _weather = data;
        _isStale = false;
        _loading = false;
      });
    } on WeatherException catch (e) {
      if (id == _requestId && mounted) _handleError(e);
    }
  }

  Future<void> _refresh() async {
    final city = _weather?.city;
    if (city != null) await _loadWeather(city);
  }

  void _handleError(WeatherException e) {
    setState(() {
      _loading = false;
      if (e.isNetwork && _weather != null) {
        _isStale = true; // offline: keep showing saved data
        _error = null;
      } else {
        _error = e.message;
      }
    });
  }

  Future<City?> _pickCity(List<City> cities) {
    return showDialog<City>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Select a city'),
        children: cities
            .map((city) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(c, city),
                  child: Text(city.label),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_loading) const LinearProgressIndicator(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: 'Search city',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _search, child: const Text('Search')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) return _message(Icons.error_outline, _error!);
    final w = _weather;
    if (w == null) {
      return _loading
          ? const Center(child: CircularProgressIndicator())
          : _message(Icons.search, 'Search for a city to see its weather');
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (_isStale) _staleBanner(w),
          _currentCard(w),
          const SizedBox(height: 16),
          Text('5-Day Forecast',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...w.forecast.map(_forecastRow),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _staleBanner(WeatherData w) {
    final time = TimeOfDay.fromDateTime(w.fetchedAt).format(context);
    return Card(
      color: Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Offline: showing saved data from $time. It may be outdated.',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }

  Widget _currentCard(WeatherData w) {
    final info = weatherInfoFor(w.weatherCode);
    final theme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(w.city.label,
                style: theme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(info.icon, style: const TextStyle(fontSize: 64)),
            Text('${w.temperature.round()}°C', style: theme.displayMedium),
            Text(info.description, style: theme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Humidity: ${w.humidity}%'),
                Text('Wind: ${w.windSpeed.round()} km/h'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _forecastRow(DailyForecast f) {
    final info = weatherInfoFor(f.weatherCode);
    return Card(
      child: ListTile(
        leading: Text(info.icon, style: const TextStyle(fontSize: 28)),
        title: Text('${_days[f.date.weekday - 1]}, ${f.date.day}/${f.date.month}'),
        subtitle: Text(info.description),
        trailing: Text('${f.minTemp.round()}° / ${f.maxTemp.round()}°C'),
      ),
    );
  }
}