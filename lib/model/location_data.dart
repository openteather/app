class LocationData {
  final double latitude;
  final double longitude;

  LocationData({required this.latitude, required this.longitude});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}
