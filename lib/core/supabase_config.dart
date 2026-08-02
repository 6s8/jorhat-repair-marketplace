/// Configuration for Supabase URL and Anon / Publishable Key.
/// Configured for Jorhat Repair & Spare Parts Marketplace backend.
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yuhnbffprqxiaxncfkma.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_I0jImnU0x-Sydh8n3X2UmQ_IlKLj7VI',
  );
}
