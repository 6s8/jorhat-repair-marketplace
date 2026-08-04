import '../../../retailer/models/spare_part_model.dart';

abstract class CustomerStoreRepository {
  Future<List<SparePart>> getAvailableSpareParts({
    String? category,
    String? searchQuery,
  });

  Stream<List<SparePart>> watchAvailableSpareParts({
    String? category,
    String? searchQuery,
  });
}
