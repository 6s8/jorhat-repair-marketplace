import '../features/booking/models/job_create_request.dart';
import '../models/job_model.dart';
import '../models/result.dart';

/// Abstract contract for Job operations.
abstract class JobRepository {
  /// Fetch current pending jobs from backend.
  Future<List<Job>> fetchPendingJobs();

  /// Watch real-time stream of pending jobs.
  Stream<List<Job>> watchPendingJobs();

  /// Atomically accept a job to prevent race conditions.
  Future<Result<Job>> acceptJob(String jobId, String technicianId);

  /// Create a new customer repair request job in Supabase.
  Future<Result<Job>> createJob(JobCreateRequest request);

  /// Mark an accepted job as completed.
  Future<Result<Job>> completeJob(String jobId, String technicianId);

  /// Fetch all active (accepted) jobs for a specific technician.
  Future<List<Job>> fetchActiveJobsForTechnician(String technicianId);
}
