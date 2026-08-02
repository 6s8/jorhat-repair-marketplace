import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_providers.dart';

/// Represents the simplified tracked status of a job for the customer-facing tracker.
enum TrackedJobStatus { requested, assigned, inProgress, completed, unknown }

/// State for a tracked job
class TrackedJobState {
  final String jobId;
  final TrackedJobStatus status;
  final String? technicianId;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final bool isLoading;
  final String? errorMessage;

  const TrackedJobState({
    required this.jobId,
    this.status = TrackedJobStatus.requested,
    this.technicianId,
    this.acceptedAt,
    this.completedAt,
    this.isLoading = true,
    this.errorMessage,
  });

  TrackedJobState copyWith({
    TrackedJobStatus? status,
    String? technicianId,
    DateTime? acceptedAt,
    DateTime? completedAt,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TrackedJobState(
      jobId: jobId,
      status: status ?? this.status,
      technicianId: technicianId ?? this.technicianId,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static TrackedJobStatus _parseStatus(String? raw, String? technicianId) {
    switch (raw) {
      case 'accepted':
        return TrackedJobStatus.assigned;
      case 'in_progress':
        return TrackedJobStatus.inProgress;
      case 'completed':
        return TrackedJobStatus.completed;
      case 'pending':
      default:
        return TrackedJobStatus.requested;
    }
  }

  static TrackedJobState fromJson(String jobId, Map<String, dynamic> json) {
    final techId = json['technician_id']?.toString();
    final rawStatus = json['status']?.toString();

    // Derive a richer status: if technician assigned but still "accepted", show inProgress after 2 min
    TrackedJobStatus status = _parseStatus(rawStatus, techId);

    return TrackedJobState(
      jobId: jobId,
      status: status,
      technicianId: techId,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())?.toLocal()
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())?.toLocal()
          : null,
      isLoading: false,
    );
  }
}

/// Riverpod StateNotifier that subscribes to real-time job status updates via Supabase.
class JobStatusTrackerNotifier extends StateNotifier<TrackedJobState> {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  JobStatusTrackerNotifier(this._client, String jobId)
      : super(TrackedJobState(jobId: jobId)) {
    _init(jobId);
  }

  Future<void> _init(String jobId) async {
    // 1. Fetch initial state
    try {
      final data = await _client
          .from('jobs')
          .select()
          .eq('id', jobId)
          .single();
      if (mounted) {
        state = TrackedJobState.fromJson(jobId, data);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, errorMessage: 'Could not load job status.');
      }
      return;
    }

    // 2. Subscribe to real-time changes
    _channel = _client
        .channel('job-tracker-$jobId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: jobId),
          callback: (payload) {
            if (mounted && payload.newRecord.isNotEmpty) {
              state = TrackedJobState.fromJson(jobId, payload.newRecord);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }
    super.dispose();
  }
}

/// Family provider — pass the job ID to get a real-time tracker for that job.
final jobStatusTrackerProvider = StateNotifierProvider.family<
    JobStatusTrackerNotifier, TrackedJobState, String>(
  (ref, jobId) {
    final client = ref.read(supabaseClientProvider);
    return JobStatusTrackerNotifier(client, jobId);
  },
);
