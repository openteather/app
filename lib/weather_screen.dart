import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:open_teather/model/forecast_data.dart';
import 'package:weather_icons/weather_icons.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:open_teather/model/weather_data.dart';

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
              'Location permissions are denied. Please enable location services in System Preferences.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Please enable location services in System Preferences.');
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable location services in System Preferences.');
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
    } else if (conditionLower.contains('rain') ||
        conditionLower.contains('showers')) {
      return WeatherIcons.rain;
    } else if (conditionLower.contains('thunderstorm') ||
        conditionLower.contains('thunder')) {
      return WeatherIcons.thunderstorm;
    } else if (conditionLower.contains('fog')) {
      return WeatherIcons.fog;
    } else if (conditionLower.contains('snow')) {
      return WeatherIcons.snow;
    } else {
      return WeatherIcons.na;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadWeather,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWeather,
                  color: colorScheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCurrentWeather(),
                        const SizedBox(height: 24),
                        _buildForecast(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCurrentWeather() {
    if (weatherData == null) return Container();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
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
                    Text(
                      '${weatherData!.current.temperature}°${weatherData!.current.temperatureUnit}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
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
      return Container();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
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
            ...weatherData!.forecast
                .map((forecast) => _buildForecastItem(forecast)),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(ForecastData forecast) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 8),
          Text(
            forecast.condition,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (forecast.detailedForecast.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              forecast.detailedForecast,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.air,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${forecast.windSpeed} ${forecast.windDirection}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
