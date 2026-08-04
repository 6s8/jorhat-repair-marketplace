import 'dart:math' as math;

/// Utility class for geographic calculations such as Haversine distance.
class LocationUtils {
  static const double _earthRadiusKm = 6371.0;

  /// Default Jorhat city center coordinates (Assam)
  static const double defaultLatitude = 26.7509;
  static const double defaultLongitude = 94.2037;

  /// Calculates the Haversine distance in kilometers between two GPS coordinates.
  static double calculateHaversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(rLat1) *
            math.cos(rLat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
