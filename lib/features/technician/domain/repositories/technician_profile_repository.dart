import '../models/technician_profile.dart';

abstract class TechnicianProfileRepository {
  /// Fetch profile for technician. If not present, creates default profile and returns it.
  Future<TechnicianProfile> getProfile(String technicianId, {String? phone});

  /// Update technician profile / radar settings.
  Future<TechnicianProfile> updateProfile(TechnicianProfile profile);
}
