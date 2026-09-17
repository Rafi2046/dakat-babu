/// Base failure class representing domain and data layer errors.
sealed class Failure {
  /// User-friendly error message.
  final String message;

  /// Optional underlying technical error code or exception details.
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Generic backend or Supabase database error.
final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'A server error occurred. Please try again.',
    super.code,
  ]);
}

/// Network connectivity failure.
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Unable to connect. Please check your internet connection.',
    super.code,
  ]);
}

/// Error returned when attempting to join a non-existent room code.
final class RoomNotFoundFailure extends Failure {
  const RoomNotFoundFailure([
    super.message = 'Room not found. Please check the code and try again.',
    super.code,
  ]);
}

/// Error returned when attempting to join a room that already has 4 players.
final class RoomFullFailure extends Failure {
  const RoomFullFailure([
    super.message = 'This room is already full (maximum 4 players).',
    super.code,
  ]);
}

/// Error returned when an action violates game rules (e.g. starting with < 4 players).
final class GameRuleFailure extends Failure {
  const GameRuleFailure(super.message, [super.code]);
}

/// Form input validation failure.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

/// Base exception class for throwing exceptions before mapping to [Failure].
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}
