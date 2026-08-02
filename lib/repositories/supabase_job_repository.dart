import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';
import '../models/result.dart';
import 'job_repository.dart';

/// Supabase implementation of [JobRepository].
///
/// Enforces atomic database updates to prevent race conditions when multiple
/// technicians attempt to accept the same job simultaneously.
class SupabaseJobRepository implements JobRepository {
  final SupabaseClient _client;

  SupabaseJobRepository(this._client);

  @override
  Future<List<Job>> fetchPendingJobs() async {
    try {
      final data = await _client
          .from('jobs')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final jobs = (data as List)
          .map((json) => Job.fromJson(json as Map<String, dynamic>))
          .where((job) => !job.isExpired)
          .toList();

      return jobs;
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<List<Job>> watchPendingJobs() {
    // Controller to emit updated list of active pending jobs
    final controller = StreamController<List<Job>>.broadcast();
    List<Job> currentJobs = [];

    // Helper to fetch and push initial state
    fetchPendingJobs().then((jobs) {
      currentJobs = jobs;
      if (!controller.isClosed) controller.add(currentJobs);
    });

    // Realtime postgres changes channel listener
    final channel = _client.channel('public:jobs');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'jobs',
      callback: (payload) {
        final eventType = payload.eventType;
        final newRecord = payload.newRecord;
        final oldRecord = payload.oldRecord;

        if (eventType == PostgresChangeEvent.insert) {
          if (newRecord.isNotEmpty) {
            final newJob = Job.fromJson(newRecord);
            if (newJob.id.isNotEmpty && newJob.status == 'pending' && !newJob.isExpired) {
              currentJobs.insert(0, newJob);
            }
          }
        } else if (eventType == PostgresChangeEvent.update) {
          if (newRecord.isNotEmpty) {
            final updatedJob = Job.fromJson(newRecord);
            if (updatedJob.status != 'pending' || updatedJob.isExpired) {
              currentJobs.removeWhere((job) => job.id == updatedJob.id);
            } else {
              final index = currentJobs.indexWhere((job) => job.id == updatedJob.id);
              if (index != -1) {
                currentJobs[index] = updatedJob;
              }
            }
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final deletedId = oldRecord['id'] as String?;
          if (deletedId != null) {
            currentJobs.removeWhere((job) => job.id == deletedId);
          }
        }

        if (!controller.isClosed) {
          controller.add(List.unmodifiable(currentJobs));
        }
      },
    ).subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<Result<Job>> acceptJob(String jobId, String technicianId) async {
    try {
      // 1. Primary Atomic Attempt: Try stored procedure RPC
      try {
        final rpcResult = await _client.rpc(
          'accept_job',
          params: {
            'p_job_id': jobId,
            'p_technician_id': technicianId,
          },
        ).timeout(const Duration(seconds: 8));

        if (rpcResult != null && (rpcResult as List).isNotEmpty) {
          final acceptedJob = Job.fromJson((rpcResult).first as Map<String, dynamic>);
          return Result.success(acceptedJob);
        }
      } catch (_) {
        // Fall back to direct atomic SQL query if RPC is not registered
      }

      // 2. Fallback Atomic Query: Single UPDATE with status & technician_id guards
      final response = await _client
          .from('jobs')
          .update({
            'status': 'accepted',
            'technician_id': technicianId,
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .eq('status', 'pending')
          .filter('technician_id', 'is', null)
          .select()
          .timeout(const Duration(seconds: 8));

      if (response.isNotEmpty) {
        final acceptedJob = Job.fromJson((response as List).first as Map<String, dynamic>);
        return Result.success(acceptedJob);
      }

      // Zero rows returned -> Job was already accepted by another technician or expired
      return Result.jobAlreadyTaken(
        'This job has already been accepted by another technician.',
      );
    } on TimeoutException {
      return Result.timeout('Network timeout. Please try again.');
    } on SocketException {
      return Result.networkError('Connection lost. Please check your internet.');
    } on PostgrestException catch (e) {
      if (e.code == 'P0001' || e.message.contains('accepted')) {
        return Result.jobAlreadyTaken('This job has already been accepted.');
      }
      return Result.unknownError(e.message);
    } catch (e) {
      return Result.unknownError('Failed to accept job: ${e.toString()}');
    }
  }
}
