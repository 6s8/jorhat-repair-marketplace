import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';
import 'technician_profile_provider.dart';

class TechnicianActiveJobsNotifier extends AsyncNotifier<List<Job>> {
  @override
  Future<List<Job>> build() async {
    final repository = ref.watch(jobRepositoryProvider);
    final technicianId = ref.watch(currentTechnicianIdProvider);
    return await repository.fetchActiveJobsForTechnician(technicianId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(jobRepositoryProvider);
      final technicianId = ref.read(currentTechnicianIdProvider);
      return await repository.fetchActiveJobsForTechnician(technicianId);
    });
  }

  Future<String?> startNavigation(String jobId) async {
    final repository = ref.read(jobRepositoryProvider);
    final technicianId = ref.read(currentTechnicianIdProvider);
    final result = await repository.updateJobStatus(jobId, technicianId, 'on_the_way');
    await refresh();
    return result.isSuccess ? null : (result.error ?? 'Failed to update status.');
  }

  Future<String?> verifyArrivalOtp(String jobId, String enteredOtp) async {
    final repository = ref.read(jobRepositoryProvider);
    final technicianId = ref.read(currentTechnicianIdProvider);
    final result = await repository.verifyArrivalOtp(jobId, technicianId, enteredOtp);
    await refresh();
    return result.isSuccess ? null : (result.error ?? 'Invalid OTP.');
  }

  Future<String?> verifyCompletionOtpAndComplete(
      String jobId, String enteredOtp, double finalAmount) async {
    final repository = ref.read(jobRepositoryProvider);
    final technicianId = ref.read(currentTechnicianIdProvider);
    final result = await repository.verifyCompletionOtpAndComplete(
        jobId, technicianId, enteredOtp, finalAmount);
    await refresh();
    return result.isSuccess ? null : (result.error ?? 'Invalid OTP or Completion failed.');
  }
}

final technicianActiveJobsProvider =
    AsyncNotifierProvider<TechnicianActiveJobsNotifier, List<Job>>(
  () => TechnicianActiveJobsNotifier(),
);
