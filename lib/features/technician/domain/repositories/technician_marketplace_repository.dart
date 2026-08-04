import '../../../retailer/models/spare_part_model.dart';

abstract class TechnicianMarketplaceRepository {
  /// Fetch all available spare parts in the marketplace.
  Future<List<SparePart>> getSpareParts({String? category, String? search});

  /// Realtime stream of spare parts.
  Stream<List<SparePart>> watchSpareParts({String? category, String? search});
}
