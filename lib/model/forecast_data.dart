class ForecastData {
  final String date;
  final String dayName;
  final bool isDaytime;
  final int temperature;
  final String temperatureUnit;
  final String condition;
  final String detailedForecast;
  final String windSpeed;
  final String windDirection;

  ForecastData({
    required this.date,
    required this.dayName,
    required this.isDaytime,
    required this.temperature,
    required this.temperatureUnit,
    required this.condition,
    required this.detailedForecast,
    required this.windSpeed,
    required this.windDirection,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      date: json['date'],
      dayName: json['day_name'],
      isDaytime: json['is_daytime'],
      temperature: json['temperature'],
      temperatureUnit: json['temperature_unit'],
      condition: json['condition'],
      detailedForecast: json['detailed_forecast'] ?? '',
      windSpeed: json['wind_speed'],
      windDirection: json['wind_direction'],
    );
  }
}
