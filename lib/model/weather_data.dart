import 'package:open_teather/model/current_weather.dart';
import 'package:open_teather/model/forecast_data.dart';
import 'package:open_teather/model/location_data.dart';

class WeatherData {
  final LocationData location;
  final CurrentWeather current;
  final List<ForecastData> forecast;

  WeatherData({
    required this.location,
    required this.current,
    required this.forecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: LocationData.fromJson(json['location']),
      current: CurrentWeather.fromJson(json['current']),
      forecast: (json['forecast'] as List)
          .map((item) => ForecastData.fromJson(item))
          .toList(),
    );
  }
}
