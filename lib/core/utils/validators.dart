import '../constants/app_constants.dart';

/// Common input validation helpers for room codes and player names.
abstract final class Validators {
  /// Validates a room join code.
  ///
  /// Must be non-empty and match [AppConstants.roomCodeLength] characters.
  static String? validateRoomCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a room code';
    }

    final trimmed = value.trim().toUpperCase();
    if (trimmed.length != AppConstants.roomCodeLength) {
      return 'Room code must be exactly ${AppConstants.roomCodeLength} characters';
    }

    final alphanumericRegex = RegExp(r'^[A-Z0-9]+$');
    if (!alphanumericRegex.hasMatch(trimmed)) {
      return 'Room code must contain only letters and numbers';
    }

    return null;
  }

  /// Validates a player display name.
  ///
  /// Must be 2-15 characters long and contain alphanumeric characters.
  static String? validatePlayerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (trimmed.length > 15) {
      return 'Name cannot exceed 15 characters';
    }

    return null;
  }

  /// General required field validator.
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
