import '../models/job_model.dart';
import '../models/result.dart';

/// Abstract contract for Job operations.
abstract class JobRepository {
  /// Fetch current pending jobs from backend.
  Future<List<Job>> fetchPendingJobs();

  /// Watch real-time stream of pending jobs.
  Stream<List<Job>> watchPendingJobs();

  /// Atomically accept a job to prevent race conditions.
  ///
  /// Guarantees that only ONE technician wins the job.
  Future<Result<Job>> acceptJob(String jobId, String technicianId);
}
