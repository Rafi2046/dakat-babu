/// Named routes and URL path helpers for DakatBabu navigation.
abstract final class AppRoutes {
  // --- Route Paths ---
  /// Home landing screen path.
  static const String home = '/';

  /// Pre-game room lobby path with roomCode parameter.
  static const String lobby = '/lobby/:roomCode';

  /// Live game round path with roomCode parameter.
  static const String gameRound = '/game/:roomCode';

  /// Post-round and match results path with roomCode parameter.
  static const String results = '/results/:roomCode';

  // --- Route Names ---
  static const String homeName = 'home';
  static const String lobbyName = 'lobby';
  static const String gameRoundName = 'gameRound';
  static const String resultsName = 'results';

  // --- Parameter Keys ---
  static const String paramRoomCode = 'roomCode';

  // --- Path Generators ---
  /// Generates the absolute path to a room's lobby.
  static String lobbyPath(String roomCode) => '/lobby/$roomCode';

  /// Generates the absolute path to an active game round.
  static String gameRoundPath(String roomCode) => '/game/$roomCode';

  /// Generates the absolute path to round results.
  static String resultsPath(String roomCode) => '/results/$roomCode';
}
