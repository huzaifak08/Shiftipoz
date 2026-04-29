import 'package:flutter_geo_hash/flutter_geo_hash.dart' show GeoPoint;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:developer' as dev;
import 'package:app_settings/app_settings.dart';
import 'package:shiftipoz/helpers/app_data.dart';

class LocationService {
  /// Fetches everything: Lat, Lng, Geohash, and City Name
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // 2. Handle Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await AppSettings.openAppSettings(type: AppSettingsType.location);
        dev.log(
          "Permission denied by user. Aborting.",
          name: 'Location Service',
        );
        return null;
      } else {
        await AppSettings.openAppSettings(type: AppSettingsType.location);
        dev.log(
          "Permission denied by user. Aborting.",
          name: 'Location Service',
        );
        return null;
      }
    }

    // 3. Get Current Position
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );

    // 4. Reverse Geocode (Get City)
    String city = "Unknown";
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        city =
            placemarks.first.locality ??
            placemarks.first.subAdministrativeArea ??
            "Unknown";
      }
    } catch (e) {
      dev.log("Geocoding error: $e");
    }

    // 5. Generate Geohash
    final geoPoint = GeoPoint(position.longitude, position.latitude);

    final String hash = AppData.shared.geoHash.geoHashForLocation(
      geoPoint,
      precision: 8,
    );

    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'hash': hash,
      'city': city,
    };
  }
}
