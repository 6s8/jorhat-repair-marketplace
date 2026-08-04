import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/job_model.dart';
import '../../domain/models/job_part.dart';
import '../../domain/repositories/job_parts_repository.dart';

class SupabaseJobPartsRepository implements JobPartsRepository {
  final SupabaseClient _client;

  SupabaseJobPartsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ── Active Jobs ──────────────────────────────────────────────────────────

  @override
  Future<List<Job>> getActiveJobs(String technicianId) async {
    try {
      final data = await _client
          .from('jobs')
          .select()
          .eq('technician_id', technicianId)
          .inFilter('status', ['accepted', 'on_the_way', 'in_progress'])
          .order('created_at', ascending: false);

      return (data as List)
          .map((j) => Job.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Job Parts ─────────────────────────────────────────────────────────────

  @override
  Future<List<JobPart>> getJobParts(String jobId) async {
    try {
      final data = await _client
          .from('job_parts')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: true);

      return (data as List)
          .map((j) => JobPart.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<JobPart> attachPartToJob({
    required String jobId,
    required String partId,
    required int quantity,
    required double technicianPrice,
    required double customerPrice,
  }) async {
    final profitMargin = customerPrice - technicianPrice;

    final payload = JobPart(
      id: '',
      jobId: jobId,
      partId: partId,
      quantity: quantity,
      technicianPrice: technicianPrice,
      customerPrice: customerPrice,
      profitMargin: profitMargin,
      createdAt: DateTime.now(),
    );

    final result = await _client
        .from('job_parts')
        .insert(payload.toInsertJson())
        .select()
        .single();

    return JobPart.fromJson(result);
  }

  @override
  Future<void> removePartFromJob(String jobPartId) async {
    await _client.from('job_parts').delete().eq('id', jobPartId);
  }
}
