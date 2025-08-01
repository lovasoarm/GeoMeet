import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationService {
  static Future<bool> checkLocationPermission() async {
    if (kIsWeb) {
      return true;
    }

    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }

  static Future<bool> checkLocationEnabled() async {
    if (kIsWeb) {
      return true;
    }
    return await Geolocator.isLocationServiceEnabled();
  }

  static Stream<Position> getPositionUpdates({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: const Duration(seconds: 30),
      ),
    ).handleError((error) {
      throw Exception('Erreur de géolocalisation: $error');
    });
  }

  static Future<Position> getCurrentPosition() async {
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Permission de localisation refusée');
    }

    final isServiceEnabled = await checkLocationEnabled();
    if (!isServiceEnabled) {
      throw Exception('Les services de localisation sont désactivés');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ),
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('Timeout lors de la récupération de la position');
      },
    );
  }
}
