import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/technician_profile.dart';
import '../../domain/repositories/technician_profile_repository.dart';

class SupabaseTechnicianProfileRepository implements TechnicianProfileRepository {
  final SupabaseClient _client;

  SupabaseTechnicianProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<TechnicianProfile> getProfile(String technicianId, {String? phone}) async {
    final defaultProfile = TechnicianProfile(
      id: technicianId,
      phone: phone ?? '+91 98765 43210',
    );

    try {
      final response = await _client
          .from('technician_profiles')
          .select()
          .eq('id', technicianId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (response != null) {
        return TechnicianProfile.fromJson(response);
      } else {
        // Automatically initialize default profile in Supabase if missing
        try {
          await _client
              .from('technician_profiles')
              .upsert(defaultProfile.toJson())
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Ignore if table/RLS blocks initial insert
        }
        return defaultProfile;
      }
    } catch (e) {
      // Fallback to default profile if table doesn't exist or offline
      return defaultProfile;
    }
  }

  @override
  Future<TechnicianProfile> updateProfile(TechnicianProfile profile) async {
    try {
      final response = await _client
          .from('technician_profiles')
          .upsert(profile.toJson())
          .select()
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (response != null) {
        return TechnicianProfile.fromJson(response);
      }
      return profile;
    } catch (e) {
      // If offline or error, return updated in-memory profile
      return profile;
    }
  }
}
