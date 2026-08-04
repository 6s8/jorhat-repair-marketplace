class AuthService {
  /// Validates Indian 10-digit mobile number format.
  static bool isValidIndianPhoneNumber(String rawNumber) {
    final cleaned = rawNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      final firstDigit = cleaned[0];
      return ['6', '7', '8', '9'].contains(firstDigit);
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      final firstDigit = cleaned[2];
      return ['6', '7', '8', '9'].contains(firstDigit);
    }
    return false;
  }

  /// Formats raw phone number to international +91 E.164 format.
  static String formatIndianPhone(String rawNumber) {
    final cleaned = rawNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '+91$cleaned';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    }
    return rawNumber.startsWith('+') ? rawNumber : '+$cleaned';
  }

  /// Humanizes technical Supabase auth error messages for end users.
  static String getReadableErrorMessage(Object error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('network') || errStr.contains('socketexception') || errStr.contains('failed to host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (errStr.contains('invalid') && errStr.contains('otp')) {
      return 'Invalid OTP code. Please check the code and try again.';
    }
    if (errStr.contains('expired') || errStr.contains('token has expired')) {
      return 'OTP has expired. Please request a new OTP.';
    }
    if (errStr.contains('rate limit') || errStr.contains('too many requests') || errStr.contains('429')) {
      return 'Too many OTP requests. Please wait a few minutes before trying again.';
    }
    if (errStr.contains('user canceled') || errStr.contains('cancelled')) {
      return 'Sign-in cancelled.';
    }
    if (errStr.contains('invalid phone')) {
      return 'Invalid phone number format.';
    }
    return error.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
  }
}
