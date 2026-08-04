import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../models/result.dart';
import '../../../../models/job_model.dart';
import '../../../../providers/job_repository_provider.dart';
import 'technician_active_jobs_provider.dart';
import 'technician_location_provider.dart';
import 'technician_profile_provider.dart';

/// Notifier for the latest job that should trigger a fullscreen popup alert.
class LatestAlertJobNotifier extends StateNotifier<Job?> {
  LatestAlertJobNotifier() : super(null);

  void triggerAlert(Job job) {
    state = job;
  }

  void clearAlert() {
    state = null;
  }
}

final latestAlertJobProvider =
    StateNotifierProvider<LatestAlertJobNotifier, Job?>((ref) {
  return LatestAlertJobNotifier();
});

/// Manages pending jobs filtered by technician skills, work radius, and online status.
class TechnicianPendingJobsNotifier extends AsyncNotifier<List<Job>> {
  StreamSubscription<List<Job>>? _sub;
  final Set<String> _seenJobIds = {};
  final Set<String> _rejectedJobIds = {};

  @override
  Future<List<Job>> build() async {
    final repository = ref.watch(jobRepositoryProvider);
    final profileState = ref.watch(technicianProfileProvider);
    final locationState = ref.watch(technicianLocationProvider);

    final profile = profileState.value;
    final location = locationState.value ?? TechnicianLocation.defaultJorhat;

    if (profile == null || !profile.isOnline) {
      _sub?.cancel();
      return [];
    }

    _sub?.cancel();

    _sub = repository.watchPendingJobs().listen((allPending) {
      final filtered = _filterJobs(allPending, profile.skills, profile.workRadiusKm, location);

      // Check for newly arrived matching jobs to trigger popup radar alert
      for (final job in filtered) {
        if (!_seenJobIds.contains(job.id) && !_rejectedJobIds.contains(job.id)) {
          _seenJobIds.add(job.id);
          // Only trigger if job is fresh (created within last 3 minutes)
          final diff = DateTime.now().difference(job.createdAt).inSeconds.abs();
          if (diff <= 180) {
            ref.read(latestAlertJobProvider.notifier).triggerAlert(job);
            break;
          }
        }
      }

      // Schedule state update in microtask to prevent updating Riverpod state during build phase
      Future.microtask(() {
        state = AsyncData(filtered);
      });
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    // Initial fetch from repository
    final initial = await repository.fetchPendingJobs();
    final filteredInitial = _filterJobs(initial, profile.skills, profile.workRadiusKm, location);
    for (final job in filteredInitial) {
      _seenJobIds.add(job.id);
    }
    return filteredInitial;
  }

  void rejectJob(String jobId) {
    _rejectedJobIds.add(jobId);
    ref.read(latestAlertJobProvider.notifier).clearAlert();
    if (state.hasValue) {
      final updated = state.value!.where((j) => j.id != jobId).toList();
      state = AsyncData(updated);
    }
  }

  Future<void> refresh() async {
    final repository = ref.read(jobRepositoryProvider);
    final profileState = ref.read(technicianProfileProvider);
    final locationState = ref.read(technicianLocationProvider);

    final profile = profileState.value;
    final location = locationState.value ?? TechnicianLocation.defaultJorhat;

    if (profile == null || !profile.isOnline) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncValue.loading();
    final initial = await repository.fetchPendingJobs();
    final filtered = _filterJobs(initial, profile.skills, profile.workRadiusKm, location);
    state = AsyncData(filtered);
  }

  List<Job> _filterJobs(
    List<Job> jobs,
    List<String> skills,
    double radiusKm,
    TechnicianLocation location,
  ) {
    final lowerSkills = skills.map((s) => s.trim().toLowerCase()).toSet();

    return jobs.where((job) {
      // Must be pending
      if (job.status != 'pending') return false;

      // Must not be rejected by technician
      if (_rejectedJobIds.contains(job.id)) return false;

      // Category & synonym matching
      final cat = (job.applianceCategory ?? job.issue).trim().toLowerCase();

      bool isMatch(String skill, String c) {
        if (skill == 'all' || c.isEmpty) return true;
        if (c.contains(skill) || skill.contains(c)) return true;

        // TV & Television synonym mapping
        if ((skill == 'tv' || skill == 'television') &&
            (c.contains('tv') || c.contains('television'))) {
          return true;
        }
        // Fridge & Refrigerator synonym mapping
        if ((skill == 'fridge' || skill == 'refrigerator') &&
            (c.contains('fridge') || c.contains('refrigerator'))) {
          return true;
        }
        // AC & Air Conditioner synonym mapping
        if ((skill == 'ac' || skill.contains('air condition')) &&
            (c.contains('ac') || c.contains('air condition'))) {
          return true;
        }
        // Chimney mapping
        if (skill.contains('chimney') && c.contains('chimney')) {
          return true;
        }
        // Geyser / Water Heater mapping
        if ((skill.contains('geyser') || skill.contains('heater')) &&
            (c.contains('geyser') || c.contains('heater'))) {
          return true;
        }
        // Purifier mapping
        if ((skill.contains('purifier') || skill.contains('ro')) &&
            (c.contains('purifier') || c.contains('ro'))) {
          return true;
        }
        // Washing machine mapping
        if (skill.contains('wash') && c.contains('wash')) {
          return true;
        }
        return false;
      }

      final skillMatch = lowerSkills.isEmpty || lowerSkills.any((skill) => isMatch(skill, cat));
      if (!skillMatch) return false;

      // Distance matching
      final jobLat = job.latitude ?? LocationUtils.defaultLatitude;
      final jobLon = job.longitude ?? LocationUtils.defaultLongitude;
      final dist = LocationUtils.calculateHaversineDistanceKm(
        location.latitude,
        location.longitude,
        jobLat,
        jobLon,
      );

      return dist <= radiusKm;
    }).map((job) {
      final jobLat = job.latitude ?? LocationUtils.defaultLatitude;
      final jobLon = job.longitude ?? LocationUtils.defaultLongitude;
      final dist = LocationUtils.calculateHaversineDistanceKm(
        location.latitude,
        location.longitude,
        jobLat,
        jobLon,
      );
      return job.copyWith(distanceKm: double.parse(dist.toStringAsFixed(1)));
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  Future<Result<Job>> acceptJob(String jobId) async {
    _seenJobIds.add(jobId);
    ref.read(latestAlertJobProvider.notifier).clearAlert();

    final repository = ref.read(jobRepositoryProvider);
    final technicianId = ref.read(currentTechnicianIdProvider);

    // Call atomic accept
    final result = await repository.acceptJob(jobId, technicianId);
    if (result.isSuccess) {
      await refresh();
      ref.invalidate(technicianActiveJobsProvider);
    }
    return result;
  }
}

final technicianPendingJobsProvider =
    AsyncNotifierProvider<TechnicianPendingJobsNotifier, List<Job>>(
  () => TechnicianPendingJobsNotifier(),
);
