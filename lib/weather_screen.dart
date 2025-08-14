import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_teather/model/forecast_data.dart';
import 'package:open_teather/model/weather_data.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  WeatherScreenState createState() => WeatherScreenState();
}

class WeatherScreenState extends State<WeatherScreen> {
  WeatherData? weatherData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12)return 'Good morning';
    if (hour < 18)return 'Good afternoon';
    if (hour < 21)return 'Good evening';

    return 'Good night';
  }

  Future<void> _loadWeather([double? lat, double? lon]) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      double latitude, longitude;

      if (lat != null && lon != null) {
        latitude = lat;
        longitude = lon;
      } else {
        Position position = await _getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      WeatherData data = await _fetchWeatherData(latitude, longitude);

      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
              'Location permissions are denied. Please enable them in your system settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Enable them in your system settings.');
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable location services.');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      throw Exception('Unable to get location: ${e.toString()}');
    }
  }

  Future<WeatherData> _fetchWeatherData(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('https://openteather.thoq.dev/weather?lat=$lat&lon=$lon'),
    );

    if (response.statusCode == 200) {
      return WeatherData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  IconData _getWeatherIcon(String condition) {
    final conditionLower = condition.toLowerCase();
    if (conditionLower.contains('sunny') || conditionLower.contains('clear')) {
      return WeatherIcons.day_sunny;
    } else if (conditionLower.contains('cloudy')) {
      return WeatherIcons.cloudy;
    } else if (conditionLower.contains('rain') || conditionLower.contains('showers')) {
      return WeatherIcons.rain;
    } else if (conditionLower.contains('thunderstorm') || conditionLower.contains('thunder')) {
      return WeatherIcons.thunderstorm;
    } else if (conditionLower.contains('fog')) {
      return WeatherIcons.fog;
    } else if (conditionLower.contains('snow')) {
      return WeatherIcons.snow;
    } else {
      return WeatherIcons.na;
    }
  }

  void _showForecastDetails(ForecastData forecast) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                forecast.dayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getWeatherIcon(forecast.condition),
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${forecast.temperature}°${forecast.temperatureUnit}',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                forecast.condition,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (forecast.detailedForecast.isNotEmpty)
                Text(
                  forecast.detailedForecast,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.air,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${forecast.windSpeed} ${forecast.windDirection}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final greeting = _getGreeting();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenTeather'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeather,
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWeather,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadWeather,
        color: colorScheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 16,
                ),
                child: Center(
                  child: Text(
                    '$greeting!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildCurrentWeather(),
            const SizedBox(height: 24),
            _buildForecast(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    if (weatherData == null) return const SizedBox();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.primaryContainer
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Current Weather',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(
                        _getWeatherIcon(weatherData!.current.condition),
                        size: 72,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: colorScheme.primaryContainer,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Text(
                          '${weatherData!.current.temperature}°${weatherData!.current.temperatureUnit}',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeatherDetail(
                        Icons.thermostat,
                        weatherData!.current.condition,
                      ),
                      const SizedBox(height: 12),
                      _buildWeatherDetail(
                        Icons.air,
                        '${weatherData!.current.windSpeed} ${weatherData!.current.windDirection}',
                      ),
                      const SizedBox(height: 12),
                      _buildWeatherDetail(
                        Icons.location_on,
                        '${weatherData!.location.latitude.toStringAsFixed(2)}, ${weatherData!.location.longitude.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildForecast() {
    if (weatherData == null || weatherData!.forecast.isEmpty) {
      return const SizedBox();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...weatherData!.forecast.map((forecast) => _buildForecastItem(forecast)),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(ForecastData forecast) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceBright,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showForecastDetails(forecast),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  forecast.dayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _getWeatherIcon(forecast.condition),
                      size: 28,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${forecast.temperature}°${forecast.temperatureUnit}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}