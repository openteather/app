class CurrentWeather {
  final int temperature;
  final String temperatureUnit;
  final String condition;
  final String windSpeed;
  final String windDirection;

  CurrentWeather({
    required this.temperature,
    required this.temperatureUnit,
    required this.condition,
    required this.windSpeed,
    required this.windDirection,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: json['temperature'],
      temperatureUnit: json['temperature_unit'],
      condition: json['condition'],
      windSpeed: json['wind_speed'],
      windDirection: json['wind_direction'],
    );
  }
}
