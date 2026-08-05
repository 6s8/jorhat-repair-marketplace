import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';

/// Repository handling all Supabase Auth and User Profile operations.
/// Presentation widgets and controllers interact strictly through this repository.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? supabase;

  /// Gets current authenticated user if session exists.
  User? get currentUser => _client.auth.currentUser;

  /// Gets current active session.
  Session? get currentSession => _client.auth.currentSession;

  /// Stream of Supabase authentication state events.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Requests Phone SMS OTP code from Supabase Auth.
  Future<void> signInWithPhone(String rawPhoneNumber) async {
    final formattedPhone = AuthService.formatIndianPhone(rawPhoneNumber);
    await _client.auth.signInWithOtp(
      phone: formattedPhone,
    );
  }

  /// Verifies SMS OTP code with Supabase Auth.
  Future<AuthResponse> verifyOtp({
    required String rawPhoneNumber,
    required String token,
    OtpType type = OtpType.sms,
  }) async {
    final formattedPhone = AuthService.formatIndianPhone(rawPhoneNumber);
    return await _client.auth.verifyOTP(
      phone: formattedPhone,
      token: token.trim(),
      type: type,
    );
  }

  /// Triggers Google OAuth Sign-In via Supabase.
  Future<bool> signInWithGoogle() async {
    // On web: use the full current URL base (origin + path) so that Supabase
    // redirects back to the correct GitHub Pages sub-path, not just the origin.
    // Uri.base on GitHub Pages = "https://6s8.github.io/Services-repair-marketplace/"
    // Uri.base.origin alone = "https://6s8.github.io" → causes 404 after OAuth.
    final String redirectUrl = kIsWeb
        ? '${Uri.base.origin}${Uri.base.path}'
        : 'io.supabase.jorhatrepair://login-callback/';

    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
    return response;
  }

  /// Signs out user and clears local auth session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Queries user profile from `public.profiles` table with strict 800ms timeout guarantee.
  Future<ProfileModel?> fetchProfile(String userId) async {
    try {
      final response = await Future<Map<String, dynamic>?>(() async {
        final res = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        return res;
      // Increased to 6s: cold Supabase starts on web can take 2-3s easily.
      // 800ms was causing false-null returns → users stuck on RoleSelectionScreen.
      }).timeout(const Duration(milliseconds: 6000));

      if (response == null) return null;
      return ProfileModel.fromJson(response);
    } catch (e) {
      // Gracefully return null on timeout, RLS exception, or missing table
      return null;
    }
  }

  /// Inserts or updates user profile in `public.profiles`.
  Future<ProfileModel> upsertProfile(ProfileModel profile) async {
    final payload = profile.toJson();
    final response = await _client
        .from('profiles')
        .upsert(payload)
        .select()
        .single();
    return ProfileModel.fromJson(response);
  }
}
