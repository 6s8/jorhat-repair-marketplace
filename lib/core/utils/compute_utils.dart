import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Helper functions for executing CPU-intensive computations on background isolates using `compute()`.
class ComputeUtils {
  /// Offloads distance calculations and job proximity sorting to a background isolate.
  static Future<List<Map<String, dynamic>>> sortJobsByProximity({
    required List<Map<String, dynamic>> rawJobs,
    required double userLat,
    required double userLng,
  }) async {
    return compute(_sortJobsIsolate, {
      'jobs': rawJobs,
      'lat': userLat,
      'lng': userLng,
    });
  }

  /// Offloads search query filtering over marketplace items to a background isolate.
  static Future<List<Map<String, dynamic>>> filterItemsByQuery({
    required List<Map<String, dynamic>> items,
    required String query,
  }) async {
    if (query.trim().isEmpty) return items;
    return compute(_filterItemsIsolate, {
      'items': items,
      'query': query.toLowerCase().trim(),
    });
  }
}

List<Map<String, dynamic>> _sortJobsIsolate(Map<String, dynamic> params) {
  final List<Map<String, dynamic>> jobs =
      List<Map<String, dynamic>>.from(params['jobs'] as List);
  final double userLat = params['lat'] as double;
  final double userLng = params['lng'] as double;

  final Distance distanceCalc = const Distance();

  jobs.sort((a, b) {
    final double latA = (a['latitude'] as num?)?.toDouble() ?? userLat;
    final double lngA = (a['longitude'] as num?)?.toDouble() ?? userLng;
    final double latB = (b['latitude'] as num?)?.toDouble() ?? userLat;
    final double lngB = (b['longitude'] as num?)?.toDouble() ?? userLng;

    final double distA = distanceCalc.as(LengthUnit.Kilometer, LatLng(userLat, userLng), LatLng(latA, lngA));
    final double distB = distanceCalc.as(LengthUnit.Kilometer, LatLng(userLat, userLng), LatLng(latB, lngB));

    return distA.compareTo(distB);
  });

  return jobs;
}

List<Map<String, dynamic>> _filterItemsIsolate(Map<String, dynamic> params) {
  final List<Map<String, dynamic>> items =
      List<Map<String, dynamic>>.from(params['items'] as List);
  final String query = params['query'] as String;

  return items.where((item) {
    final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
    final category = (item['category'] ?? '').toString().toLowerCase();
    final brand = (item['brand'] ?? '').toString().toLowerCase();

    return title.contains(query) || category.contains(query) || brand.contains(query);
  }).toList();
}
