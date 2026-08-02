import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_providers.dart';
import '../repositories/job_repository.dart';
import '../repositories/supabase_job_repository.dart';

/// Provider for [JobRepository].
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseJobRepository(supabase);
});
