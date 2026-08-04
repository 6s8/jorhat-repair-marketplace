import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_technician_profile_repository.dart';
import '../../domain/models/technician_profile.dart';
import '../../domain/repositories/technician_profile_repository.dart';

final technicianProfileRepositoryProvider =
    Provider<TechnicianProfileRepository>((ref) {
  return SupabaseTechnicianProfileRepository();
});

/// Current technician user ID provider (can be overridden by auth provider in full app).
final currentTechnicianIdProvider = Provider<String>((ref) {
  return '00000000-0000-4000-8000-000000000001';
});

class TechnicianProfileNotifier extends AsyncNotifier<TechnicianProfile> {
  late TechnicianProfileRepository _repository;
  late String _technicianId;

  @override
  Future<TechnicianProfile> build() async {
    _repository = ref.watch(technicianProfileRepositoryProvider);
    _technicianId = ref.watch(currentTechnicianIdProvider);
    return await _repository.getProfile(_technicianId);
  }

  Future<void> updateSkills(List<String> newSkills) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(skills: newSkills);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateProfile(updated));
  }

  Future<void> updateWorkRadius(double radiusKm) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(workRadiusKm: radiusKm);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateProfile(updated));
  }

  Future<void> updateAlertTimer(int timerSec) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(alertTimerSec: timerSec);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateProfile(updated));
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(isOnline: isOnline);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateProfile(updated));
  }

  Future<void> saveProfile(TechnicianProfile updatedProfile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateProfile(updatedProfile));
  }
}

final technicianProfileProvider =
    AsyncNotifierProvider<TechnicianProfileNotifier, TechnicianProfile>(
  () => TechnicianProfileNotifier(),
);
