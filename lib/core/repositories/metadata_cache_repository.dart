import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory cache repository for static metadata (Assam cities, categories, brand lists).
/// Reduces redundant network and memory allocations across all entry points.
class MetadataCacheRepository {
  static final MetadataCacheRepository _instance = MetadataCacheRepository._internal();
  factory MetadataCacheRepository() => _instance;
  MetadataCacheRepository._internal();

  final Map<String, _CacheItem<dynamic>> _cache = {};

  /// Retrieves cached item if available and not expired.
  T? get<T>(String key) {
    final item = _cache[key];
    if (item == null) return null;
    if (item.isExpired) {
      _cache.remove(key);
      return null;
    }
    return item.data as T?;
  }

  /// Stores item in cache with specified Time-To-Live (default: 30 minutes).
  void set<T>(String key, T data, {Duration ttl = const Duration(minutes: 30)}) {
    _cache[key] = _CacheItem<T>(
      data: data,
      expiry: DateTime.now().add(ttl),
    );
  }

  /// Clears specific cache key or entire cache.
  void clear([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  /// Pre-populated static list of Assam cities & towns.
  List<String> getAssamCities() {
    const cachedKey = 'assam_cities';
    final cached = get<List<String>>(cachedKey);
    if (cached != null) return cached;

    const cities = [
      'Jorhat',
      'Guwahati',
      'Dibrugarh',
      'Silchar',
      'Tezpur',
      'Nagaon',
      'Tinsukia',
      'Bongaigaon',
      'Sivasagar',
      'Golaghat',
      'Lakhimpur',
      'Dhubri',
      'Karimganj',
      'Goalpara',
      'Barpeta',
    ];
    set(cachedKey, cities, ttl: const Duration(hours: 24));
    return cities;
  }

  /// Pre-populated static list of repair appliance categories.
  List<String> getApplianceCategories() {
    const cachedKey = 'appliance_categories';
    final cached = get<List<String>>(cachedKey);
    if (cached != null) return cached;

    const categories = [
      'AC',
      'Refrigerator',
      'Washing Machine',
      'Television',
      'Car AC',
      'Water Purifier',
      'Inverter & Battery',
      'Geyser',
      'Cooler',
      'Kitchen Chimney',
      'Microwave Oven',
    ];
    set(cachedKey, categories, ttl: const Duration(hours: 24));
    return categories;
  }

  /// Pre-populated brand list.
  List<String> getApplianceBrands() {
    const cachedKey = 'appliance_brands';
    final cached = get<List<String>>(cachedKey);
    if (cached != null) return cached;

    const brands = [
      'LG',
      'Samsung',
      'Whirlpool',
      'Voltas',
      'Daikin',
      'Haier',
      'Godrej',
      'Panasonic',
      'Blue Star',
      'IFB',
      'Bosch',
      'Lloyd',
      'Sony',
      'Kent',
      'Livpure',
    ];
    set(cachedKey, brands, ttl: const Duration(hours: 24));
    return brands;
  }
}

class _CacheItem<T> {
  final T data;
  final DateTime expiry;

  _CacheItem({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Riverpod provider for MetadataCacheRepository singleton.
final metadataCacheRepositoryProvider = Provider<MetadataCacheRepository>((ref) {
  return MetadataCacheRepository();
});
