import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

/// Provides a single, global Supabase instance for all entry points.
SupabaseClient get supabase => Supabase.instance.client;

/// Initializes Supabase. Should only be called once during app bootstrap.
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );
}
