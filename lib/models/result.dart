/// Sealed Result type for repository operations.
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.jobAlreadyTaken([String? message]) = JobAlreadyTaken<T>;
  factory Result.networkError([String? message]) = NetworkError<T>;
  factory Result.timeout([String? message]) = Timeout<T>;
  factory Result.unknownError([String? message]) = UnknownError<T>;

  bool get isSuccess => this is Success<T>;

  String? get error => switch (this) {
        Success<T>() => null,
        JobAlreadyTaken<T>(:final message) => message,
        NetworkError<T>(:final message) => message,
        Timeout<T>(:final message) => message,
        UnknownError<T>(:final message) => message,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) jobAlreadyTaken,
    required R Function(String message) networkError,
    required R Function(String message) timeout,
    required R Function(String message) unknownError,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      JobAlreadyTaken<T>(:final message) => jobAlreadyTaken(message),
      NetworkError<T>(:final message) => networkError(message),
      Timeout<T>(:final message) => timeout(message),
      UnknownError<T>(:final message) => unknownError(message),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class JobAlreadyTaken<T> extends Result<T> {
  final String message;
  const JobAlreadyTaken([
    String? message,
  ]) : message = message ?? 'This job has already been accepted by another technician.';
}

class NetworkError<T> extends Result<T> {
  final String message;
  const NetworkError([
    String? message,
  ]) : message = message ?? 'Connection lost. Please check your network.';
}

class Timeout<T> extends Result<T> {
  final String message;
  const Timeout([
    String? message,
  ]) : message = message ?? 'Network timeout. Please try again.';
}

class UnknownError<T> extends Result<T> {
  final String message;
  const UnknownError([
    String? message,
  ]) : message = message ?? 'An unexpected error occurred.';
}
