import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';

/// Provider for AuthRepository singleton instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream of Supabase Auth state updates.
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Provider for current authenticated Supabase User.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateStreamProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

/// ProfileNotifier managing profile lookup and onboarding persistence.
class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final AuthRepository _repo;

  ProfileNotifier(this._repo, User? user)
      : super(user != null ? const AsyncValue.loading() : const AsyncValue.data(null)) {
    if (user != null) {
      loadProfile(user.id);
    }
  }

  Future<void> loadProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repo.fetchProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ProfileModel?> saveOnboarding({
    required String userId,
    required String fullName,
    required String role,
    String? phone,
    String? email,
  }) async {
    final existing = state.value;
    final newProfile = ProfileModel(
      id: userId,
      fullName: fullName,
      role: role.toLowerCase(),
      phone: phone ?? existing?.phone,
      email: email ?? existing?.email,
      avatarUrl: existing?.avatarUrl,
    );

    state = const AsyncValue.loading();
    try {
      final saved = await _repo.upsertProfile(newProfile);
      state = AsyncValue.data(saved);
      return saved;
    } catch (e) {
      // Fallback to local profile object if server table RLS or network fails
      state = AsyncValue.data(newProfile);
      return newProfile;
    }
  }

  void clearProfile() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for user profile. Automatically reloads when currentUser changes.
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return ProfileNotifier(repo, user);
});

/// Provider exposing current user's role.
final roleProvider = Provider<String?>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.asData?.value?.role;
});

/// UI State for Authentication forms.
class AuthUiState {
  final bool isLoading;
  final String? errorMessage;
  final String? phoneNumber;
  final bool isOtpSent;

  const AuthUiState({
    this.isLoading = false,
    this.errorMessage,
    this.phoneNumber,
    this.isOtpSent = false,
  });

  AuthUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? phoneNumber,
    bool? isOtpSent,
  }) {
    return AuthUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOtpSent: isOtpSent ?? this.isOtpSent,
    );
  }
}

/// AuthController handling user actions (send OTP, verify OTP, Google sign in, sign out).
class AuthController extends StateNotifier<AuthUiState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthController(this._repo, this._ref) : super(const AuthUiState());

  /// Sends OTP to phone number.
  Future<bool> sendOtp(String phone) async {
    if (!AuthService.isValidIndianPhoneNumber(phone)) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid 10-digit Indian phone number.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.signInWithPhone(phone);
      state = state.copyWith(
        isLoading: false,
        phoneNumber: phone,
        isOtpSent: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthService.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  /// Verifies OTP code.
  Future<bool> verifyOtp(String otpToken) async {
    final phone = state.phoneNumber;
    if (phone == null || phone.isEmpty) {
      state = state.copyWith(errorMessage: 'Phone number is missing.');
      return false;
    }
    if (otpToken.trim().length < 4) {
      state = state.copyWith(errorMessage: 'Please enter valid OTP code.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repo.verifyOtp(
        rawPhoneNumber: phone,
        token: otpToken,
      );
      state = state.copyWith(isLoading: false);
      if (response.user != null) {
        await _ref.read(profileProvider.notifier).loadProfile(response.user!.id);
      }
      return response.user != null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthService.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  /// Triggers Google Sign In.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _repo.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthService.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  /// Resets back to Phone Input mode.
  void resetPhoneInput() {
    state = const AuthUiState();
  }

  /// Signs out user.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repo.signOut();
    _ref.read(profileProvider.notifier).clearProfile();
    state = const AuthUiState();
  }
}

/// Provider for AuthController.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthUiState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo, ref);
});
