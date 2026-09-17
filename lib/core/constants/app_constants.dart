/// Application constants for DakatBabu.
///
/// Contains game rules, Supabase table identifiers, timeout settings,
/// and backend configuration keys.
abstract final class AppConstants {
  // --- Application Metadata ---
  /// Human-readable application title.
  static const String appName = 'DakatBabu';

  /// Application semantic version string.
  static const String appVersion = '1.0.0';

  /// Tagline used across splash and landing screens.
  static const String appTagline = 'The Royal Chor-Police Party Game';

  // --- Game Rule Constraints ---
  /// Required minimum number of players to start a round.
  static const int minPlayers = 4;

  /// Required maximum number of players per classic game room.
  static const int maxPlayers = 4;

  /// Length of the alphanumeric room join code.
  static const int roomCodeLength = 6;

  /// Duration in seconds for the Police's deduction phase.
  static const int roundTimeoutSeconds = 30;

  /// Total number of rounds in a standard match.
  static const int defaultTotalRounds = 5;

  /// Inactivity timeout in minutes before an idle waiting lobby is flagged.
  static const int lobbyTimeoutMinutes = 10;

  /// Maximum attempts to generate a collision-free room code.
  static const int maxRoomCodeRetries = 5;

  // --- Role Point Values ---
  /// Points awarded to the Raja (King).
  static const int rajaPoints = 1000;

  /// Points awarded to the Mantri (Minister).
  static const int mantriPoints = 800;

  /// Points awarded to the Police when the Chor is correctly identified.
  static const int policeCorrectPoints = 500;

  /// Points awarded to the Chor if Police fails to identify them.
  static const int chorSuccessPoints = 500;

  /// Points awarded to the Chor when caught by Police.
  static const int chorCaughtPoints = 0;

  /// Points awarded to the Police when they guess incorrectly.
  static const int policeWrongPoints = 0;

  // --- Supabase Table Names ---
  /// Database table for game rooms.
  static const String roomsTable = 'rooms';

  /// Database table for joined players.
  static const String playersTable = 'players';

  /// Database table for round status and role distribution.
  static const String roundsTable = 'game_rounds';

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

/// The 4 traditional game roles in Chor-Police-Raja-Mantri.
enum GameRole {
  /// King (1000 points) - declares themself at the start of the round.
  raja,

  /// Minister (800 points) - assists the court.
  mantri,

  /// Police/Inspector (500 points) - must identify the Chor among remaining suspects.
  police,

  /// Thief/Dakat (0 or 500 points) - attempts to deceive the Police.
  chor;

  /// Parses a string into a [GameRole], returning null if not found.
  static GameRole? tryParse(String? value) {
    if (value == null) return null;
    return GameRole.values.cast<GameRole?>().firstWhere(
          (r) => r?.name.toLowerCase() == value.toLowerCase(),
          orElse: () => null,
        );
  }
}

