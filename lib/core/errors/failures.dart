import 'package:equatable/equatable.dart';

/// Base Failure class representing domain-level errors.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Thrown when a job has already been accepted by another technician.
class JobAlreadyTakenFailure extends Failure {
  const JobAlreadyTakenFailure([
    super.message = 'This job has already been accepted by another technician.',
  ]);
}

/// Thrown when a network request times out.
class NetworkTimeoutFailure extends Failure {
  const NetworkTimeoutFailure([
    super.message = 'Network timeout. Please try again.',
  ]);
}

/// Thrown when internet connection is lost.
class SocketFailure extends Failure {
  const SocketFailure([
    super.message = 'Connection lost. Please check your internet connection.',
  ]);
}

/// Thrown for Supabase-specific database errors.
class SupabaseFailure extends Failure {
  const SupabaseFailure(super.message);
}

/// Thrown when user is unauthorized or session expired.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Unauthorized session. Please log in again.',
  ]);
}

/// General fallback failure.
class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred. Please try again.',
  ]);
}
