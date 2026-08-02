import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import 'job_repository_provider.dart';

/// Notifier managing real-time list of pending nearby repair jobs.
class RealtimeJobListNotifier extends StateNotifier<AsyncValue<List<Job>>> {
  final Ref _ref;
  StreamSubscription<List<Job>>? _subscription;
  Timer? _expiryCheckTimer;

  RealtimeJobListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initRealtimeFeed();
    _startExpiryCleanupTimer();
  }

  void _initRealtimeFeed() {
    final repository = _ref.read(jobRepositoryProvider);
    state = const AsyncValue.loading();

    _subscription?.cancel();
    _subscription = repository.watchPendingJobs().listen(
      (jobs) {
        state = AsyncValue.data(jobs);
      },
      onError: (err, stack) {
        state = AsyncValue.error(err, stack);
      },
    );
  }

  /// Manually pull to refresh
  Future<void> refresh() async {
    final repository = _ref.read(jobRepositoryProvider);
    try {
      final jobs = await repository.fetchPendingJobs();
      state = AsyncValue.data(jobs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Remove a job optimistically from local UI state
  Job? optimisticallyRemoveJob(String jobId) {
    final currentList = state.value;
    if (currentList == null) return null;

    final index = currentList.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      final removedJob = currentList[index];
      final newList = List<Job>.from(currentList)..removeAt(index);
      state = AsyncValue.data(newList);
      return removedJob;
    }
    return null;
  }

  /// Restore job to list if optimistic update fails
  void restoreJob(Job job) {
    final currentList = state.value ?? [];
    if (!currentList.any((j) => j.id == job.id)) {
      final newList = List<Job>.from(currentList)..insert(0, job);
      state = AsyncValue.data(newList);
    }
  }

  /// Timer checking and purging expired jobs every second
  void _startExpiryCleanupTimer() {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentList = state.value;
      if (currentList != null && currentList.isNotEmpty) {
        final activeJobs = currentList.where((job) => !job.isExpired).toList();
        if (activeJobs.length != currentList.length) {
          state = AsyncValue.data(activeJobs);
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _expiryCheckTimer?.cancel();
    super.dispose();
  }
}

/// Riverpod Provider for real-time job feed
final realtimeJobListProvider =
    StateNotifierProvider<RealtimeJobListNotifier, AsyncValue<List<Job>>>((ref) {
  return RealtimeJobListNotifier(ref);
});
