import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../models/result.dart';
import 'job_repository_provider.dart';
import 'realtime_job_list_provider.dart';

/// State of Job Acceptance action
class AcceptJobState {
  final bool isLoading;
  final String? loadingJobId;
  final String? errorMessage;
  final Job? acceptedJob;

  const AcceptJobState({
    this.isLoading = false,
    this.loadingJobId,
    this.errorMessage,
    this.acceptedJob,
  });

  AcceptJobState copyWith({
    bool? isLoading,
    String? loadingJobId,
    String? errorMessage,
    Job? acceptedJob,
  }) {
    return AcceptJobState(
      isLoading: isLoading ?? this.isLoading,
      loadingJobId: loadingJobId ?? this.loadingJobId,
      errorMessage: errorMessage,
      acceptedJob: acceptedJob ?? this.acceptedJob,
    );
  }
}

/// Controller handling optimistic job acceptance logic
class AcceptJobController extends StateNotifier<AcceptJobState> {
  final Ref _ref;

  AcceptJobController(this._ref) : super(const AcceptJobState());

  /// Execute atomic job acceptance with optimistic UI updates
  Future<Result<Job>> acceptJob({
    required String jobId,
    required String technicianId,
  }) async {
    // Set loading state for specific job
    state = state.copyWith(isLoading: true, loadingJobId: jobId, errorMessage: null);

    // Optimistically remove job card from list UI
    final listNotifier = _ref.read(realtimeJobListProvider.notifier);
    final removedJob = listNotifier.optimisticallyRemoveJob(jobId);

    final repository = _ref.read(jobRepositoryProvider);
    final result = await repository.acceptJob(jobId, technicianId);

    result.when(
      success: (acceptedJob) {
        state = state.copyWith(
          isLoading: false,
          loadingJobId: null,
          acceptedJob: acceptedJob,
        );
      },
      jobAlreadyTaken: (message) {
        // Do not restore card because job is taken by someone else
        state = state.copyWith(
          isLoading: false,
          loadingJobId: null,
          errorMessage: message,
        );
      },
      networkError: (message) {
        // Rollback: Restore job card to UI list
        if (removedJob != null) {
          listNotifier.restoreJob(removedJob);
        }
        state = state.copyWith(
          isLoading: false,
          loadingJobId: null,
          errorMessage: message,
        );
      },
      timeout: (message) {
        // Rollback: Restore job card to UI list
        if (removedJob != null) {
          listNotifier.restoreJob(removedJob);
        }
        state = state.copyWith(
          isLoading: false,
          loadingJobId: null,
          errorMessage: message,
        );
      },
      unknownError: (message) {
        // Rollback: Restore job card to UI list
        if (removedJob != null) {
          listNotifier.restoreJob(removedJob);
        }
        state = state.copyWith(
          isLoading: false,
          loadingJobId: null,
          errorMessage: message,
        );
      },
    );

    return result;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for [AcceptJobController]
final acceptJobControllerProvider =
    StateNotifierProvider<AcceptJobController, AcceptJobState>((ref) {
  return AcceptJobController(ref);
});
