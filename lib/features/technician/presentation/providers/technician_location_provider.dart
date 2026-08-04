import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/location_utils.dart';

class TechnicianLocation {
  final double latitude;
  final double longitude;

  const TechnicianLocation({
    required this.latitude,
    required this.longitude,
  });

  static const defaultJorhat = TechnicianLocation(
    latitude: LocationUtils.defaultLatitude,
    longitude: LocationUtils.defaultLongitude,
  );
}

final technicianLocationProvider = FutureProvider<TechnicianLocation>((ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return TechnicianLocation.defaultJorhat;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return TechnicianLocation.defaultJorhat;
      }
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    ).timeout(const Duration(seconds: 4));

    return TechnicianLocation(latitude: pos.latitude, longitude: pos.longitude);
  } catch (_) {
    return TechnicianLocation.defaultJorhat;
  }
});
