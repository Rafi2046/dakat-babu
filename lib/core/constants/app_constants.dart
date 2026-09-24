/// Application constants for Chor Police Dakat Babu.
library;

export '../../domain/game/game_role.dart';

/// Application constants for Chor Police Dakat Babu.
///
/// Contains game rules, Supabase table identifiers, timeout settings,
/// and backend configuration keys.
abstract final class AppConstants {
  // --- Application Metadata ---
  /// Human-readable application title.
  static const String appName = 'Chor Police Dakat Babu';

  /// Application semantic version string.
  static const String appVersion = '1.0.0';

  /// Tagline used across splash and landing screens.
  static const String appTagline = 'চোর ধরো, নিজে ধরা খেও না!';

  // --- Game Rule Constraints (locked 2A: exactly 4 players) ---
  /// Required minimum number of players to start a round.
  static const int minPlayers = 4;

  /// Required maximum number of players per game room.
  static const int maxPlayers = 4;

  /// Default player count for standard rooms.
  static const int defaultPlayers = 4;

  /// Length of the alphanumeric room join code.
  static const int roomCodeLength = 5;

  /// Duration in seconds for the Police's deduction phase.
  static const int roundTimeoutSeconds = 30;

  /// Total number of rounds in a standard match.
  static const int defaultTotalRounds = 5;

  /// Inactivity timeout in minutes before an idle waiting lobby is flagged.
  static const int lobbyTimeoutMinutes = 10;

  /// Maximum attempts to generate a collision-free room code.
  static const int maxRoomCodeRetries = 5;

  // --- Scoring (locked 1A: +1 system) ---
  /// Points awarded on a correct Police catch (Chor).
  static const int policeCorrectPoints = 1;

  /// Points awarded to the selected suspect on a wrong guess.
  static const int wrongGuessSuspectPoints = 1;

  /// Deep link scheme for QR join.
  static const String joinDeepLinkScheme = 'dakatbabu';

  /// Builds a join deep-link URI for [roomCode].
  static String joinDeepLink(String roomCode) =>
      '$joinDeepLinkScheme://join/$roomCode';

  // --- Supabase Table Names ---
  /// Database table for game rooms.
  static const String roomsTable = 'rooms';

  /// Database table for joined players.
  static const String playersTable = 'players';

  /// Database table for round status and role distribution.
  static const String roundsTable = 'game_rounds';

  /// Private per-player role rows (RLS scoped).
  static const String privateRolesTable = 'player_private_roles';

  // --- Supabase Realtime Channels ---
  /// Channel prefix for room-specific realtime events.
  static const String roomChannelPrefix = 'room_channel_';

  // --- Supabase Credentials ---
  /// Supabase project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mmenawzudnbmbihnggme.supabase.co/rest/v1/',
  );

  /// Supabase anonymous/publishable API key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_71YQPyqy2UQepo5rkdFQVw_nqPXV7V9',
  );

  /// Clean base Supabase URL for client SDK (strips any trailing /rest/v1/ or slashes).
  static String get cleanSupabaseUrl {
    var url = supabaseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/rest/v1')) {
      url = url.substring(0, url.length - '/rest/v1'.length);
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
