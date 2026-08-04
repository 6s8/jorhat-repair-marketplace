import '../../../../models/job_model.dart';
import '../models/job_part.dart';

/// Contract for all job-parts operations in the marketplace module.
abstract class JobPartsRepository {
  /// Fetch all parts attached to a given job.
  Future<List<JobPart>> getJobParts(String jobId);

  /// Attach a spare part to an active job.
  /// Returns the created [JobPart].
  Future<JobPart> attachPartToJob({
    required String jobId,
    required String partId,
    required int quantity,
    required double technicianPrice,
    required double customerPrice,
  });

  /// Remove an attached part from a job.
  Future<void> removePartFromJob(String jobPartId);

  /// Fetch active jobs for the given technician.
  /// Status must be one of: accepted, on_the_way, in_progress.
  Future<List<Job>> getActiveJobs(String technicianId);
}
