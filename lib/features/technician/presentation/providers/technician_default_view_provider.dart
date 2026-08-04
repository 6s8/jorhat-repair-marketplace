import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDefaultViewPrefKey = 'fixly_technician_default_view_map';

/// Provider managing the technician's preferred default dispatch feed view.
/// `false` = List View, `true` = Map View.
/// Automatically persists to SharedPreferences across browser refreshes and restarts.
class TechnicianDefaultViewNotifier extends StateNotifier<bool> {
  TechnicianDefaultViewNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIsMap = prefs.getBool(_kDefaultViewPrefKey);
      if (savedIsMap != null) {
        state = savedIsMap;
      }
    } catch (_) {
      // Fallback to initial state if storage is blocked
    }
  }

  Future<void> setDefaultView(bool isMapView) async {
    state = isMapView;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDefaultViewPrefKey, isMapView);
    } catch (_) {
      // Ignore write errors
    }
  }
}

final technicianDefaultViewProvider =
    StateNotifierProvider<TechnicianDefaultViewNotifier, bool>((ref) {
  return TechnicianDefaultViewNotifier();
});
