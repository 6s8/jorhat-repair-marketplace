import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';
import 'technician_profile_provider.dart';

class TechnicianEarningsSummary {
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final int completedJobsCount;
  final double totalCommission;
  final double totalNetPayout;

  const TechnicianEarningsSummary({
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.completedJobsCount,
    required this.totalCommission,
    required this.totalNetPayout,
  });

  factory TechnicianEarningsSummary.fromJobs(List<Job> jobs) {
    final now = DateTime.now();
    double today = 0.0;
    double weekly = 0.0;
    double monthly = 0.0;
    double totalNet = 0.0;
    double totalComm = 0.0;

    for (final job in jobs) {
      final gross = job.finalAmount ?? job.price;
      final net = gross * 0.9;
      final comm = gross * 0.1;

      totalNet += net;
      totalComm += comm;

      final completedDate = job.completedAt ?? job.updatedAt ?? job.createdAt;
      final diffDays = now.difference(completedDate).inDays.abs();

      if (completedDate.year == now.year &&
          completedDate.month == now.month &&
          completedDate.day == now.day) {
        today += net;
      }

      if (diffDays <= 7) {
        weekly += net;
      }

      if (completedDate.year == now.year && completedDate.month == now.month) {
        monthly += net;
      }
    }

    return TechnicianEarningsSummary(
      todayEarnings: today,
      weeklyEarnings: weekly,
      monthlyEarnings: monthly,
      completedJobsCount: jobs.length,
      totalCommission: totalComm,
      totalNetPayout: totalNet,
    );
  }
}

class TechnicianCompletedJobsNotifier extends AsyncNotifier<List<Job>> {
  @override
  Future<List<Job>> build() async {
    final repository = ref.watch(jobRepositoryProvider);
    final technicianId = ref.watch(currentTechnicianIdProvider);
    return await repository.fetchCompletedJobsForTechnician(technicianId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(jobRepositoryProvider);
      final technicianId = ref.read(currentTechnicianIdProvider);
      return await repository.fetchCompletedJobsForTechnician(technicianId);
    });
  }
}

final technicianCompletedJobsProvider =
    AsyncNotifierProvider<TechnicianCompletedJobsNotifier, List<Job>>(
  () => TechnicianCompletedJobsNotifier(),
);

final technicianEarningsSummaryProvider =
    Provider<AsyncValue<TechnicianEarningsSummary>>((ref) {
  final completedState = ref.watch(technicianCompletedJobsProvider);
  return completedState.whenData(
    (jobs) => TechnicianEarningsSummary.fromJobs(jobs),
  );
});
