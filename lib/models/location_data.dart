import 'dart:convert';

class LocationData {
  final double latitude;
  final double longitude;
  final String geohash;
  final String cityName;
  final String addressHidden;
  LocationData({
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.cityName,
    required this.addressHidden,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? geohash,
    String? cityName,
    String? addressHidden,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      cityName: cityName ?? this.cityName,
      addressHidden: addressHidden ?? this.addressHidden,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'cityName': cityName,
      'addressHidden': addressHidden,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      geohash: map['geohash'] ?? '',
      cityName: map['cityName'] ?? '',
      addressHidden: map['addressHidden'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationData.fromJson(String source) =>
      LocationData.fromMap(json.decode(source));
}
